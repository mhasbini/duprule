# (c) mhasbini 2016
package Utils;

sub new {
	my $class = shift;
	my %parm  = @_;
	my $this  = {};
	bless $this, $class;
	return $this;
}

sub compare {
	# 10+x faster than using is_deep
	# ($ref1, $ref2)
	# 0 diffrent | 1 same
	my $self = shift;
	my %pos_1 = %{ $_[0]->{pos} };
	my %pos_2 = %{ $_[1]->{pos} };
	my %substitution_1 = %{ $_[0]->{substitution} };
	my %substitution_2 = %{ $_[1]->{substitution} };
	my @keys_pos_1 = sort {$a <=> $b} keys %pos_1;
	my @keys_pos_2 = sort {$a <=> $b} keys %pos_2;
	my @keys_substitution_1 = sort {$a <=> $b} keys %substitution_1;
	my @keys_substitution_2 = sort {$a <=> $b} keys %substitution_2;
	# compare keys
	return 0 unless compare_array(\@keys_pos_1, \@keys_pos_2);
	return 0 unless compare_array(\@keys_substitution_1, \@keys_substitution_2);
	# compare pos
	foreach my $i (@keys_pos_1) {
		return 0 if(	$pos_1{$i}->{ascii_shift} != $pos_2{$i}->{ascii_shift} || $pos_1{$i}->{bitwize_shift} != $pos_2{$i}->{bitwize_shift} || 
						$pos_1{$i}->{case} ne $pos_2{$i}->{case});
		if($pos_1{$i}->{value} eq $pos_2{$i}->{value} && $pos_1{$i}->{value} eq '') { # check element only if {value} eq ''
			return 0 if $pos_1{$i}->{element} != $pos_2{$i}->{element};
		}else{
			return 0 if $pos_1{$i}->{value} ne $pos_2{$i}->{value};
		}
	}
	# compare substitution
	foreach my $i (@keys_substitution_1) {
		return 0 if $substitution_1{$i} ne $substitution_2{$i};
	}
	return 1; # same YAY!
}

sub compare_array {
	my @array_1 = @{ shift; };
	my @array_2 = @{ shift; };
	# compare sorted arrays
	# 1. if number of keys is diffrent
	if(scalar @array_1 != scalar @array_2) {
		return 0;
	}
	# 2. check elements
	# for pos
	my $is_different = 0;
	for(my $i = 0; $i < scalar @array_1; $i++) {
		if($array_1[$i] != $array_2[$i]) {
			$is_different = 1;
		}
	}
	if($is_different == 1) {
		return 0;
	}
	return 1;
}

1;