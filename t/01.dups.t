use Test::More;
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/../";

require_ok Rules;
require_ok Utils;

my $engine = Rules->new(verbose => 0);
my $util = Utils->new();

my @ok_pairs = ( ['', ':', ' '], ['cl', 'l'], ['cu', 'u'], ['C', 'uC'], ['rr', ':'],
								 ['r', 'rrr'], ['lt', 'u'], ['tt', ':'], ['crt', 'cccrrrttt'], ['T1T1T2', ':T2'],
								 ['p0', 'd'], ['ld', 'lp0'], ['dd', 'p1'], ['dddu', 'p2u'], ['{{{{}}}}', ':'],
								 ['^a[', ':'], ['^a^bl[[', 'l'], ['$a$b]]c', 'c'], ['[', 'D0'], ['O02', 'D0D0'],
								 ['O01', '['], ['^aO01', ':'], ['i0!', '^!'], ['i0ai0b', '^a^b'], ['z2[[', ':'],
								 ['Z1]', ':'], ['$aZ1]]', ':'], ['^a^bk', '^b^a'], ['$a$bK', '$b$a'], ['*01', 'k'],
								 ['kk', 'KK'], ['kk', ':'], ['*23*32', ':'], ['+1+2-1-2', ':'], ['L1R1', ':'], ['R1 L1', ':'],
								 ['^a^b.0', '^a^a'], ['^a^b,1', '^b^b'], ['^ay1', '^a^a'], ['$bY1', '$b$b'], ['y0', ':'],
								 ['Y0', ':'], ['$a]$a', '$a'], ["'4", 'x04'], ['z4*23', 'z5D1' , 'z4'], ['saa', ':'],
								 ['^a[^a', '^a'], ['L1R1', ''], ['^asab', '^bsab'], ['sab@b', '@b@a'], ['@s@s', '@s'],
								 ['@a@b', '@b@a'], ['@asab', '@a'], ['^a@a', '@a'], ['o0a[', '['], ['^bo0a', '^a'],
								 ['^aD0', ':'], ['\'0i0a', '\'0$a', '\'0^a'], ['^d o1u', 'o0d i1u'], ['l^a', '^Al'],
								 ['$au', 'u$A'], ['\'0i0at', '\'0i0A'], ['lo1a', 'o1Al'], ['^1l', 'l^1'], ['$ac', 'c$a'],
								 ['o1ac', 'co1a'], ['^!{', '$!']

			);

my @not_ok_pairs = (['^a', '^b'], ['cu', 'c'], ['C', 'u'], ['r', ':'], ['r', 'rr'],
										['lt', 'l'], ['ttt', ':'], ['sa!r', 's2*r', 'sdXr', 'r', 'sw-r', 's1wr', 's9_r'],
										['+8', '+9'], ['sab@b', '@b'], ['@asab$a', '@a'], ['-8', '-9'],
										['i5w*57', '*65i7w'], ['sabsbc', 'sbc', 'sac', 'sadsdc'], ["'3i3a", '\'3$a'],
										['^a', '^A'], ['$a', '$A'], ['i0a', 'i0A'], ['o1a', 'o1A'], ['^a^A', '^A^A'],
										['^ac', 'c^a', 'c^A'], ['$ac', 'c$A'], ['i0ac', 'ci0a', 'ci0A'],
										['o1ac', 'co1A'], ['saA', 'saa', 'sAa']
			);

foreach my $pair (@ok_pairs) {
	my @result;
	my @temp;
	$result[$_] = $engine->proccess(@{$pair}[$_]) for (0, 1);
	# is_deeply($result[0], $result[1], @{$pair}[0] ." & ". @{$pair}[1] ." Duplicates");
	# ok($util->compare($result[0], $result[1]), @{$pair}[0] ." & ". @{$pair}[1] ." Duplicates");
	push(@temp, $util->generate_id($result[$_])) for 0 .. @result - 1;
	my $is_same = uniq(@temp) == 1 ? 1 : 0;
	ok($is_same, @{$pair}[0] ." & ". @{$pair}[1] ." Duplicates");
}

foreach my $pair (@not_ok_pairs) {
	my @result;
	my @temp;
	$result[$_] = $engine->proccess(@{$pair}[$_]) for 0 .. scalar(@{$pair}) - 1;
	push(@temp, $util->generate_id($result[$_])) for 0 .. @result - 1;
	my $is_different = uniq(@temp) == @result ? 1 : 0;
	ok($is_different, join(" & ", @{$pair}) ." Different");
}

done_testing();

sub uniq {
    my %seen;
    grep !$seen{$_}++, @_;
}
