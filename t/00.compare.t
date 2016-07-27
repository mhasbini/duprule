use Test::More;
use FindBin;
use lib "$FindBin::Bin/../";

require_ok Utils;

my $util = Utils->new(); 
my $VAR1 = {'pos' => {'0' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 1, 'value' => ''},
						'1' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 2, 'value' => 'a'}},
			'substitution' => {'a' => 'b', 'c' => 'd'}};
my $VAR2 = {'pos' => {'0' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 1, 'value' => ''},
						'1' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 3, 'value' => 'a'}},
			'substitution' => {'a' => 'b', 'c' => 'd'}};
my $VAR3 = {'pos' => {'0' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 1, 'value' => ''},
						'1' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 2, 'value' => 'a'},
						'2' => {'ascii_shift' => 0, 'bitwize_shift' => 1, 'case' => 'd', 'element' => 2, 'value' => 'a'}},
			'substitution' => {'a' => 'b', 'c' => 'd'}};
my $VAR4 = {'pos' => {'0' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 1, 'value' => ''},
						'1' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 2, 'value' => 'a'},
						'2' => {'ascii_shift' => 0, 'bitwize_shift' => 1, 'case' => 'd', 'element' => 3, 'value' => 'a'}},
			'substitution' => {'a' => 'b', 'c' => 'd'}};
my $VAR5 = {'pos' => {'0' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 1, 'value' => ''},
						'1' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 2, 'value' => 'a'}},
			'substitution' => {'a' => 'b', 'c' => 'd'}};
my $VAR6 = {'pos' => {'0' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 1, 'value' => ''},
						'1' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 2, 'value' => 'a'}},
			'substitution' => {'a' => 'b', 'c' => 'd', 'e' => 'f'}};
my $VAR7 = {'pos' => {'0' => {'ascii_shift' => 0, 'bitwize_shift' => -5, 'case' => 'd', 'element' => 1, 'value' => ''},
						'1' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 2, 'value' => 'a'}},
			'substitution' => {'a' => 'b', 'c' => 'd'}};
my $VAR8 = {'pos' => {'0' => {'ascii_shift' => 2, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 1, 'value' => ''},
						'1' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 2, 'value' => 'a'}},
			'substitution' => {'a' => 'b', 'c' => 'd'}};
my $VAR9 = {'pos' => {'0' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'd', 'element' => 1, 'value' => ''},
						'1' => {'ascii_shift' => 0, 'bitwize_shift' => 0, 'case' => 'l', 'element' => 2, 'value' => 'a'}},
			'substitution' => {'a' => 'b', 'c' => 'd'}};

ok( $util->compare($VAR1, $VAR2), "same value, different element");
ok( $util->compare($VAR1, $VAR5), "same");
ok( !$util->compare($VAR1, $VAR3), "diffrent pos");
ok( $util->compare($VAR3, $VAR4), "same value, different element");
ok( !$util->compare($VAR1, $VAR6), "same pos, different substitution");
ok( !$util->compare($VAR1, $VAR7), "different bitwize_shift");
ok( !$util->compare($VAR1, $VAR8), "different ascii_shift");
ok( !$util->compare($VAR1, $VAR9), "different case");

done_testing();