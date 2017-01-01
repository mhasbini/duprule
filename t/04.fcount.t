use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib/";

require_ok Rules;

my $engine = Rules->new();

my @data = (['saa', 1], ['sbc saa', 2], ['$a $b  s$a', 3], ['s a sab', 2],
            ['sa  $b', 2]);

my ($rule, $ecount, $__, $fcount);

foreach my $pair (@data) {
  ($rule, $ecount) = @{$pair};
  ($__, $fcount) = $engine->proccess($rule);
  is($fcount, $ecount, "count for $rule");
}

done_testing();
