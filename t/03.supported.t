use Test::More;
use FindBin;
use lib "$FindBin::Bin/../";

require_ok Utils;

my $util = Utils->new();

my @supported_rules = (':', 'l', 'u', 'c', 'C', 't', 'T2', 'r', 'd', 'p0', 'f', '{', '}', '$.',
                       '^{', '[', ']', 'D1', 'x3A', 'OG0', 'iL!', 'oAG', '\'Z', 's1.', '@2',
                       'z4', 'Z5', 'q', 'k', 'K', '*0Z', 'L9', 'RL', '+O', '-8', '.3', ',5',
                       'yR', 'YP', 'x3L', 's..', 'o0m i1i', 'Za');

my @not_supported_rules = ('D!', 'Z&', '*a$', 'R$', '+*', '-#', ',)', 'y()', 'sabb', '@', 'T',
                         '^', '$', 'D', 'x1:', 'p', ',,', '..');

foreach my $rule (@supported_rules) {
  ok($util->is_supported($rule), "$rule supported");
}

foreach my $rule (@not_supported_rules) {
  ok(!$util->is_supported($rule), "$rule not supported");
}


done_testing();
