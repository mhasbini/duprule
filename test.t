use Test::More;
use Test::Deep;
use Data::Dumper;
require_ok Rules;
my $engine = Rules->new(verbose => 0);

# my %return = $engine->proccess(['ul', 'l']);
# my @keys = keys %return;
# is_deeply($engine->proccess('cl'), $engine->proccess('l'), 'Duplicate');
# is_deeply($engine->proccess('cu'), $engine->proccess('u'), 'Duplicate');
# is_deeply($engine->proccess('C'), $engine->proccess('uC'), 'Duplicate');
# is_deeply($engine->proccess('r'), $engine->proccess('rr'), 'Duplicate');
# is_deeply($engine->proccess('lt'), $engine->proccess('u'), 'Duplicate');
# is_deeply($engine->proccess('tt'), $engine->proccess(':'), 'Duplicate');
# is_deeply($engine->proccess('crt'), $engine->proccess('Ctl'), 'Duplicate');
my @pairs = (['cl', 'l'], ['cu', 'u'], ['C', 'uC'], ['rr', ':'], ['r', 'rrr'], ['lt', 'u'], ['tt', ':'], ['crt', 'cccrrrttt']);
my @result;
foreach my $pair (@pairs)
{
	$result[$_] = $engine->proccess(@{$pair}[$_]) for (0, 1);
	is_deeply($result[0], $result[1], @{$pair}[0] ." & ". @{$pair}[1] ." Duplicates");
}
# my %return = $engine->proccess(['cl', 'l']);
# my @keys = keys %return;
# is_deeply($return{$keys[0]}, $return{$keys[1]}, 'Duplicate');
done_testing();