use strict;
use warnings;
use Utils;
use Rules;
use File::Slurp qw/read_file/;
use Data::Dumper;

# $| = 1;
my $start = time;

print "- Loading rules ... ";
my @rules = grep {substr($_, 0, 1) ne '#'} read_file($ARGV[0]);
chomp @rules;
print " loaded ". scalar @rules. " rule.\n";

my $engine = Rules->new(verbose => 0);
my $util = Utils->new();

my %results;

print "- Proccessing rules ... ";
foreach my $rule (@rules) {
	# print "\t-> $rule\n";
	my $temp = $engine->proccess($rule);
	$results{$rule} = $util->generate_id($temp) unless $temp eq "RULE_IS_NOT_SUPPORTED";
}
print "done in ", time - $start,"s.\n";

$start = time;

print "- Checking for duplicates ... ";
my %reverse;
while(	my(	$rule, $hash ) = each %results){
    push @{$reverse{$hash}}, $rule;
}
print "done in ", time - $start,"s.\n";

foreach my $hash (keys %reverse) {
	if(scalar(@{$reverse{$hash}}) > 1) {
		print "$hash -> ", join(', ', @{$reverse{$hash}}),"\n";
	}
}