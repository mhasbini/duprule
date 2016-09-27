use Test::More;
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/../";

require_ok DupRules;

my $DupRules = DupRules->new();
my @cases = ({'in' => [], 'out' => []}, {'in' => ['lllll', 'll'], 'out' => ['ll']}, {'in' => ['lllll', 'lllll'], 'out' => ['lllll']}, );

foreach my $case (@cases) {
  is_deeply($DupRules->duprule($case->{'in'}), $case->{'out'})
}

done_testing();
