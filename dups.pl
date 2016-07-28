use strict;
use warnings;
use Data::Dumper;
use Rules;
my $engine = Rules->new(verbose => 0);
foreach my $rule (@ARGV) {
	my $return = $engine->proccess($rule);
	print Dumper $return;
}