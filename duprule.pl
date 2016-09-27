use strict;
use warnings;
use DupRules;

my @rules;

while (my $rule = <STDIN>) {
	chomp $rule;
	push @rules, $rule;
}

my $DupRules = DupRules->new();

foreach my $rule (@{$DupRules->duprule(\@rules)}) {
	print $rule, "\n";
}
