use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin";
use DupRules;

my @rules;

while (my $rule = <STDIN>) {
	chomp $rule;
	push @rules, $rule;
}

my $DupRules = DupRules->new();

my ($uniq, $duplicates) = $DupRules->duprule(\@rules);

open my $out, '>', 'duplicates.txt';
foreach my $dup (@{$duplicates}) {
	print $out join(', ', @{$dup}), "\n";
}
close $out;

foreach my $rule (@{$uniq}) {
	print $rule, "\n";
}
