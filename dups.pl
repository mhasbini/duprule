use strict;
use warnings;
use Data::Dumper;
use Rules;
my $engine = Rules->new(verbose => 1);
foreach my $rule (@ARGV)
{
	my $return = $engine->proccess($rule);
	print Dumper $return;
}

# my $return = $engine->proccess(':');
# print Dumper $return;