use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib/";

require_ok Utils;
require_ok Rules;

my $util = Utils->new();
my $engine = Rules->new();

my @valid_rules = ("i7e L7 L7");


foreach my $rule (@valid_rules) {
  like($util->generate_id($engine->proccess($rule)), qr/[a-f0-9]{32}/i, "$rule id is valid");
}

done_testing();
