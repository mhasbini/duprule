use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin";
use DupRules;
use Utils;

my @rules;
my $util = Utils->new();

while (my $rule = <STDIN>) {
	chomp $rule;
	if ($util->is_supported($rule)) {
		push @rules, $rule;
	}else{
		print $rule, "\n";
	}
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
