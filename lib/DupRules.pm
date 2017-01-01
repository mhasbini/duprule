package DupRules;
use strict;
use warnings;
use Rules;
use Utils;
use List::Util qw(uniq);
use Data::Dumper;

sub new {
	my $class = shift;
	my %parm  = @_;
	my $this  = {};
	bless $this, $class;
	$this->{magic} = $parm{magic} || 36; # 0-9 + A-Z + 1
	$this->{engine} = Rules->new(magic => $this->{magic});
	$this->{util} = Utils->new();
	$this->{verbose} = $parm{verbose} || 0;
	return $this;
}

sub duprule {
	my $self = shift;
	my @rules = @{ shift; };
	my $engine = $self->{engine};
	my $util = $self->{util};
	my %results;

	foreach my $rule (@rules) {
		print "-> processing $rule ... \n" if $self->{verbose};
		my ($temp, $fcount) = $engine->proccess($rule);
		$results{$rule} = {'hash' => $util->generate_id($temp), 'fcount' => $fcount};
	}

	my %reverse;
	my @return;
	my @duplicate;
	my @all_duplicates;
	my @holder;

	foreach my $rule (@rules) {
		my $value = $results{$rule};
		push @{$reverse{$value->{'hash'}}}, [$rule, $value->{'fcount'}];
		push @holder, $value->{'hash'};
	}

	undef %results; # free memory
	foreach my $hash (uniq @holder) {
		if(scalar(@{$reverse{$hash}}) > 1) { # if more then 1 rule have same hash
			my @context = @{$reverse{$hash}};
			# get rule with minimum fuctions
			my $fcount_min = $context[0][1];
			my $fcount_min_index = 0;
			my @value;
			for(my $i = 0; $i < scalar(@context); $i++) {
				@value = @{$context[$i]};
				if($value[1] < $fcount_min) {
					$fcount_min = $value[1];
					$fcount_min_index = $i;
				}
				push @duplicate, $context[$i][0];
			}
			push @all_duplicates, [@duplicate];
			undef @duplicate;
			push @return, $context[$fcount_min_index][0];
		}else{
			push @return, $reverse{$hash}->[0]->[0];
		}
	}

	return wantarray() ? (\@return, \@all_duplicates) : \@return;
}

1;
