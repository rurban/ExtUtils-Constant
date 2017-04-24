use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'ExtUtils::Constant',
    'VERSION_FROM' => 'lib/ExtUtils/Constant.pm', # finds $VERSION
    'AUTHOR'       => 'Reini Urban <rurban@cpan.org>',
    'ABSTRACT'     => 'generate XS code to import C header constants',
    # Added to the core somewhere around 5.7.2.
    'INSTALLDIRS'  => ($] >= 5.007002 && $] <= 5.012) ? 'perl' : 'site',
    'PREREQ_PM'    => { 'IPC::Cmd' => 0 }, # for can_run, in core since 5.9.5
    'LICENSE'   => 'perl_5',
    ($ExtUtils::MakeMaker::VERSION gt '6.46' ?
    ('META_MERGE' => {
         resources => {
             repository => 'https://github.com/rurban/ExtUtils-Constant/',
             bugtracker => 'https://github.com/rurban/ExtUtils-Constant/issues/',
             license    => 'http://dev.perl.org/licenses/',
         },
     }) : ()),
    clean => { FILES => "ext-[0-9]*" },
    SIGN => 1,
);

if ($] > 5.005_50 && $] < 5.006001) {
  warn <<"EORANT";

The tests for this module will fail on perl 5.6.0
Perl 5.6.0 contains many many Unicode bugs fixed in 5.6.1 which are impossible
to work round. Please upgrade to at least 5.6.1, preferably 5.8.0.

Bug reports from 5.6.0 users (even users on OS X dependent on Apple to ship
5.6.1) will be acknowledged, tested on 5.6.1, and if not repeatable on 5.6.1
will be noted as known failures due to 5.6.0, with no further action taken.

I am sorry if this sounds unhelpful, but I have better things to do with
the limited free time I can donate to this module than to go chasing bugs
known to already have a fix.

EORANT
}

package MY;
sub test {
    local $_ = shift->SUPER::test(@_);
    s/\tPERL_DL_NONLAZY=1/\t+PERL_DL_NONLAZY=1/;
    $_;
}
sub depend {
  "
release : dist
	git tag \$(VERSION)
	cpan-upload \$(DISTVNAME).tar\$(SUFFIX)
	git push
	git push --tags

GCOV = gcov
test_cover :: pure_all
	\$(RM_RF) cover_db
	+\$(PERLRUNINST) -S cover -test

test_coveralls :: pure_all
	+\$(PERLRUNINST) -S cover -test -report coveralls

gcov : \$(BASEEXT).c.gcov \$(BASEEXT).gcov cover_db/\$(BASEEXT)-xs.html

\$(BASEEXT).c.gcov \$(BASEEXT).xs.gcov : \$(BASEEXT).xs
	\$(MAKE) CCFLAGS=\"\$(CCFLAGS) -fprofile-arcs -ftest-coverage\" LDDLFLAGS=\"\$(LDDLFLAGS) -fprofile-arcs -ftest-coverage\"
	\$(GCOV) \$(BASEEXT).c \$(BASEEXT).xs

cover_db/\$(BASEEXT)-xs.html : \$(BASEEXT).xs.gcov
	PERL5OPT=-MDevel::Cover make test
	-$^X -S gcov2perl \$(BASEEXT).c.gcov \$(BASEEXT).xs.gcov
	$^X -S cover

gprof :
	\$(MAKE) CCFLAGS=\"\$(CCFLAGS) -pg\" LDDLFLAGS=\"\$(LDDLFLAGS) -pg\"
"
}
