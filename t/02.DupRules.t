use Test::More;
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/../";

require_ok DupRules;

my $DupRules = DupRules->new();
my @cases = ({'in' => [], 'out' => [], 'dups' => []},
             {'in' => ['u', 'lllll', 'll'], 'out' => ['u', 'll'], 'dups' => [['ll', 'lllll']]},
             {'in' => ['lllll', 'lllll'], 'out' => ['lllll'], 'dups' => []}, # identical rules, so 'dups is empty'
             {'in' => ['u', 'lu', 'l', 'll', ':'], 'out' => ['u', 'l', ':'], 'dups' => [['u', 'lu'], ['l', 'll']]}
            );

foreach my $case (@cases) {
  my ($uniq, $dups) = $DupRules->duprule($case->{'in'});
  is_deeply([sort @{$uniq}], [sort @{$case->{'out'}}]);
  ok(cmpAoAs($dups, $case->{'dups'}));
}

sub cmpAoAs {
    my( $a, $b ) = @_;
    my %h;
    $h{ $_ }++ for map{ @$_ } @$a;
    $h{ $_ }-- for map{ @$_ } @$b;
    return 0 == grep{ $_ } values %h;
}

done_testing();
