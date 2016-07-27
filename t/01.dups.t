use Test::More;
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/../";

require_ok Rules;
require_ok Utils;

my $engine = Rules->new(verbose => 0);
my $util = Utils->new(); 

my @pairs = (	['cl', 'l'], ['cu', 'u'], ['C', 'uC'], ['rr', ':'], ['r', 'rrr'], ['lt', 'u'], ['tt', ':'],
				['crt', 'cccrrrttt'], ['T1T1T2', ':T2'], ['p0', 'd'], ['ld', 'lp0'], ['dd', 'p1'], ['dddu', 'p2u'],
				['{{{{}}}}', ':'], ['^a[', ':'], ['^a^bl[[', 'l'], ['$a$b]]c', 'c'], ['[', 'D0'], ['O02', 'D0D0'],
				['O01', '['], ['^aO01', ':'], ['i0!', '^!'], ['i0ai0b', '^a^b'], ["'4", 'x04'], ['z2[[', ':'],
				['Z1]', ':'], ['$aZ1]]', ':'], ['^a^bk', '^b^a'], ['$a$bK', '$b$a'], ['*01', 'k'], ['kk', 'KK'],
				['kk', ':'], ['*23*32', ':'], ['+1+2-1-2', ':'],['L1R1', ':'], ['R1 L1', ':'], ['^a^b.0', '^a^a'],
				['^a^b,1', '^b^b'], ['^ay1', '^a^a'], ['$bY1', '$b$b'], ['y0', ':'], ['Y0', ':']
			);
my @result;

foreach my $pair (@pairs)
{
	$result[$_] = $engine->proccess(@{$pair}[$_]) for (0, 1);
	# is_deeply($result[0], $result[1], @{$pair}[0] ." & ". @{$pair}[1] ." Duplicates");
	ok($util->compare($result[0], $result[1]), @{$pair}[0] ." & ". @{$pair}[1] ." Duplicates");
}

done_testing();