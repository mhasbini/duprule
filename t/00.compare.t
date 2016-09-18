use Test::More;
use FindBin;
use lib "$FindBin::Bin/../";

require_ok Utils;

my $util = Utils->new();
my $VAR1 = [{'pos' => {'0' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 1, 'value' => ''}},'substitution' => {'a' => 'b', 'c' => 'd'}},
			{'pos' => {'0' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 1, 'value' => ''},
					   '1' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => -1, 'value' => 'a'}}}
			];
my $VAR2 = [{'pos' => {'0' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 1, 'value' => ''}},'substitution' => {'a' => 'b', 'c' => 'd'}},
			{'pos' => {'0' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 1, 'value' => ''},
					   '1' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => -1, 'value' => 'b'}}}
			];
my $VAR3 = [{'pos' => {'0' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 1, 'value' => ''}},'substitution' => {'a' => 'b', 'c' => 'd'}},
			{'pos' => {'0' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 1, 'value' => ''},
					   '1' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => -1, 'value' => 'a'}}}
			];
my $VAR4 = [{'pos' => {'0' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 1, 'value' => ''}},'substitution' => {'a' => 'b'}},
			{'pos' => {'0' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 1, 'value' => ''},
					   '1' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => -1, 'value' => 'a'}}}
			];
my $VAR5 = [{'pos' => {'0' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 1, 'value' => ''}},'substitution' => {'a' => 'b', 'e' => 'd'}},
			{'pos' => {'0' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 1, 'value' => ''},
					   '1' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => -1, 'value' => 'a'}}}
			];
my $VAR6 = [{'pos' => {'0' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 1, 'value' => ''}},'substitution' => {'a' => 'b', 'c' => 'd', 'l' => 'm'}},
			{'pos' => {'0' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 1, 'value' => ''},
					   '1' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => -1, 'value' => 'a'}}}
			];
my $VAR7 = [{'pos' => {'0' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 1, 'value' => ''}},'substitution' => {'a' => 'b', 'c' => 'd'}},
			{'pos' => {'0' => {'ascii_shift' => 0, 'bitwize_shift' => 3, 'case' => 'd', 'element' => 1, 'value' => ''},
					   '1' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => -1, 'value' => 'a'}}}
			];
my $VAR8 = [{'pos' => {'0' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 1, 'value' => ''}},'substitution' => {'a' => 'b', 'c' => 'd'}},
			{'pos' => {'0' => {'ascii_shift' => 0, 'bitwize_shift' => -5, 'case' => 'd', 'element' => 1, 'value' => ''},
					   '1' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => -1, 'value' => 'a'}}}
			];
my $VAR9 = [{'pos' => {'0' => {'ascii_shift' => 3, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 1, 'value' => ''}},'substitution' => {'a' => 'b', 'c' => 'd'}},
			{'pos' => {'0' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 1, 'value' => ''},
					   '1' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => -1, 'value' => 'a'}}}
			];
my $VAR10 = [{'pos' => {'0' => {'ascii_shift' => -5, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 1, 'value' => ''}},'substitution' => {'a' => 'b', 'c' => 'd'}},
			{'pos' => {'0' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 1, 'value' => ''},
					   '1' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => -1, 'value' => 'a'}}}
			];
my $VAR11 = [{'pos' => {'0' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'l', 'element' => 1, 'value' => ''}},'substitution' => {'a' => 'b', 'c' => 'd'}},
			{'pos' => {'0' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 1, 'value' => ''},
					   '1' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => -1, 'value' => 'a'}}}
			];
my $VAR12 = [{'pos' => {'0' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 1, 'value' => ''}},'substitution' => {'a' => 'b', 'c' => 'd'}},
			{'pos' => {'0' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 1, 'value' => ''},
					   '1' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'u', 'element' => -1, 'value' => 'a'}}}
			];
my $VAR13 = [{'pos' => {'0' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 1, 'value' => ''}},'substitution' => {'a' => 'b', 'c' => 'd'}},
			{'pos' => {'0' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'b', 'element' => 1, 'value' => ''},
					   '1' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => -1, 'value' => 'a'}}}
			];
my $VAR14 = [{'pos' => {'0' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 1, 'value' => ''}},'substitution' => {'a' => 'b', 'c' => 'd'}}];

ok( $util->generate_id($VAR1) eq $util->generate_id($VAR3), "same");
ok( $util->generate_id($VAR1) ne $util->generate_id($VAR2), "diffrent value");
ok( $util->generate_id($VAR1) ne $util->generate_id($VAR14), "diffrent pos");
ok( $util->generate_id($VAR1) ne $util->generate_id($VAR4), "different substitution");
ok( $util->generate_id($VAR1) ne $util->generate_id($VAR5), "different substitution");
ok( $util->generate_id($VAR1) ne $util->generate_id($VAR6), "different substitution");
ok( $util->generate_id($VAR1) ne $util->generate_id($VAR7), "different bitwize_shift");
ok( $util->generate_id($VAR1) ne $util->generate_id($VAR8), "different bitwize_shift");
ok( $util->generate_id($VAR1) ne $util->generate_id($VAR9), "different ascii_shift");
ok( $util->generate_id($VAR1) ne $util->generate_id($VAR10), "different ascii_shift");
ok( $util->generate_id($VAR1) ne $util->generate_id($VAR11), "different case");
ok( $util->generate_id($VAR1) ne $util->generate_id($VAR12), "different case");
ok( $util->generate_id($VAR1) ne $util->generate_id($VAR13), "different case");

done_testing();
