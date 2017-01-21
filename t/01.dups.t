use Test::More;
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use List::Util qw(uniq);

require_ok Rules;
require_ok Utils;

my $engine = Rules->new(verbose => 0);
my $util = Utils->new();

my @dups = (
	['', ':', ' '], ['cl', 'l'], ['cu', 'u'], ['C', 'uC'], ['rr', ':'],
	['r', 'rrr'], ['lt', 'u'], ['tt', ':'], ['crt', 'cccrrrttt'], ['T1T1T2', ':T2'],
	['p0', 'd'], ['ld', 'lp0'], ['dd', 'p1'], ['dddu', 'p2u'], ['{{{{}}}}', ':'],
	['^a[', ':'], ['^a^bl[[', 'l'], ['$a$b]]c', 'c'], ['[', 'D0'], ['O02', 'D0D0'],
	['O01', '['], ['^aO01', ':'], ['i0!', '^!'], ['i0ai0b', '^a^b'], ['z2[[', ':'],
	['Z1]', ':'], ['$aZ1]]', ':'], ['^a^bk', '^b^a'], ['$a$bK', '$b$a'], ['*01', 'k'],
	['kk', 'KK'], ['kk', ':'], ['*23*32', ':'], ['+1+2-1-2', ':'], ['L1R1', ':'], ['R1 L1', ':'],
	['^a^b.0', '^a^a'], ['^a^b,1', '^b^b'], ['^ay1', '^a^a'], ['$bY1', '$b$b'], ['y0', ':'],
	['Y0', ':'], ['$a]$a', '$a'], ["'4", 'x04'], ['z4*23', 'z5D1' , 'z4'], ['saa', ':'],
	['^a[^a', '^a'], ['^asab', '^bsab'], ['sab@b', '@b@a'], ['@s@s', '@s'],
	['@a@b', '@b@a'], ['@asab', '@a'], ['^a@a', '@a'], ['o0a[', '['], ['^bo0a', '^a'],
	['^aD0', ':'], ['\'0i0a', '\'0$a', '\'0^a'], ['l^a', '^Al'],
	['$au', 'u$A'], ['\'0i0at', '\'0i0A'], ['lo1a', 'o1Al'], ['^1l', 'l^1'], ['$ac', 'c$a'],
	['o1ac', 'co1a'], ['^!{', '$!'], ["'3i3a", "'3i4a"], ['+1 -1', '-1 +1'],
	['O06 Z4', '.1 O06 Z4', '+1 O06 Z4', 'L1 O06 Z4'], ['sab sdc smn', 'sdc sab smn'],
	["sab '6", "'6 sab"], ['i1c sab', 'sab i1c'], ['o0c sab', 'sab o0c'], ['o0a sab', 'sab o0b'],
	['sab@a', 'sab'], ['R0saa', 'saaR0'], ['i8k y5 O69', 'y5 O68'], ['i1c R1 sab', 'sab i1c R1']
);

my @diff = (
	['^a', '^b'], ['cu', 'c'], ['C', 'u'], ['r', ':'], ['r', 'rr'],
	['lt', 'l'], ['ttt', ':'], ['sa!r', 's2*r', 'sdXr', 'r', 'sw-r', 's1wr', 's9_r'],
	['+8', '+9'], ['sab@b', '@b'], ['@asab$a', '@a'], ['-8', '-9'],
	['i5w*57', '*65i7w'], ['sabsbc', 'sbc', 'sac', 'sadsdc'], ["'3i3a", '\'3$a'],
	['^a', '^A'], ['$a', '$A'], ['i0a', 'i0A'], ['o1a', 'o1A'], ['^a^A', '^A^A'],
	['^ac', 'c^a', 'c^A'], ['$ac', 'c$A'], ['i0ac', 'ci0a', 'ci0A'],
	['o1ac', 'co1A'], ['saA', 'saa', 'sAa'], ['^d o1u', 'o0d i1u'], # differ at strings with length 1
	['R2c', 'cR2'], ['L1 l', 'l L1'], ['} +3 u', '} u +3'], ['} -3 u', '} u -3'],
	['+1 c', '+2 -1 c'], ['+1', '+2 -1'], ['sab R3', 'R3 sab'], ['sab L3', 'L3 sab'],
	['sab +3', '+3 sab'], ['sab -3', '-3 sab'], ['c sl1 T5', 'c T5 sl1', 'c so0 T6', 'c T6 so0'],
	['i4b +5 l', 'i4b l +5'], ['R0 +3 t', 'R0 t +3'], ['i1c R1 sab', 'sab R1 i1c'], ['i1c R1 s12', 's12 i1c R1'],
	['^b -5 s9l', '^b s9l -5'], ['i5E +6 c', 'i5E c +6'], ['R0sab', 'sabR0'], ['lsab', 'sabl', 'saBl'], ['usAb', 'sAbu'], ['csab', 'sabc'], ['i1asab', 'sabi1a'], ['o0a sab', 'sab o0a'], ['R1@a', '@aR1'], ['@asab^a', '@a^asab'], ['l@a', '@al'],
	['t', 't+2', 't+3', 't+6', 't+8', 't+9', 't-3', 't-6-1', 't-A', 'tL4', 'tR0'], ['tZ3', 'tZ3+8'], ['tz2', 'tz2L2']
);

foreach my $pair (@dups) {
	my @result;
	my @temp;
	$result[$_] = $engine->proccess(@{$pair}[$_]) for 0 .. scalar(@{$pair}) - 1;
	push(@temp, $util->generate_id($result[$_])) for 0 .. @result - 1;
	my $is_same = uniq(@temp) == 1 ? 1 : 0;
	ok($is_same, join(" & ", @{$pair}) ." Duplicates");
}

foreach my $pair (@diff) {
	my @result;
	my @temp;
	$result[$_] = $engine->proccess(@{$pair}[$_]) for 0 .. scalar(@{$pair}) - 1;
	push(@temp, $util->generate_id($result[$_])) for 0 .. @result - 1;
	my $is_different = uniq(@temp) == @result ? 1 : 0;
	ok($is_different, join(" & ", @{$pair}) ." Different");
}

done_testing();
