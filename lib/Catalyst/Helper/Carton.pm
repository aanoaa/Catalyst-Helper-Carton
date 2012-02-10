package Catalyst::Helper::Carton;
# ABSTRACT: Generate F<run> and F<test> files based on C<carton exec>
use strict;
use warnings;

sub mk_stuff {
    my($self, $helper, @args) = @_;

    my $base = $helper->{base};

    my $run_script = File::Spec->catfile($base, "run");
    $helper->render_file('run', $run_script);
    chmod 0755, $run_script;

    my $test_script = File::Spec->catfile($base, "test");
    $helper->render_file('test', $test_script);
    chmod 0755, $test_script;
    print "------------------------------------------\n";
    print " Don't forget to add below to Makefile.PL \n";
    print "------------------------------------------\n";
    print 'requires "Starman";', "\n";
    print 'requires "Devel::Cover";', "\n";
    print 'requires "Perl::Metrics::Lite";', "\n";
    print 'requires "TAP::Formatter::JUnit";', "\n";
    print "------------------------------------------\n";
    print "and then\n";
    print "> carton install\n";
    print "------------------------------------------\n";

}

=head1 SYNOPSIS

    $ script/myapp_create.pl Carton
    # add dependencies to Makefile.PL
    $ carton install
    $ ./run    # required app.psgi
    $ ./test   # generate some test report for jenkins

=head1 DESCRIPTION

This helper will create F<run> and F<test> script for jenkins environment.

=head1 SEE ALSO

L<Carton>

=cut

1;

__DATA__

__run__
#!/bin/sh
carton exec -Ilib -- starman --workers 1 -p 3000 app.psgi

__test__
#!/bin/sh

[ -f Makefile ] && make realclean
[ -d logs ] && rm -rf logs/
[ -f checkstyle-result.xml ] && rm -f checkstyle-result.xml
[ -d cover_db ] && carton exec -Ilib -- cover -delete

mkdir logs/

HARNESS_PERL_SWITCHES=-MDevel::Cover=+ignore,local,+ignore,root \
CATALYST_DEBUG=0 \
carton exec -Ilib -- prove --timer --formatter TAP::Formatter::JUnit t/ > logs/tests.xml
carton exec -Ilib -- cover -report clover
carton exec -Ilib -- cover
carton exec -Ilib -- measureperl-checkstyle --max_sub_lines 60 --max_sub_mccabe_complexity 13 --directory lib > checkstyle-result.xml
