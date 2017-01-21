package DupRules;
use strict;
use warnings;
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

	foreach my $rule (uniq @rules) {
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
# (c) mhasbini 2016
package Rules;
use strict;
# use warnings;
use warnings FATAL => 'all';
use vars qw($VERSION);
use Data::Dumper;
use Storable 'dclone';

$VERSION = '0.01';
$Data::Dumper::Sortkeys = 1;

sub new {
	my $class = shift;
	my %parm  = @_;
	my $this  = {};
	bless $this, $class;
	$this->{verbose} = $parm{verbose} || 0;
	$this->{magic} = $parm{magic} || 36; # 0-9 + A-Z + 1
	# $this->{element}{0} = {}
	$this->{rules} = {
	# General
	':'	=> sub {
			my @rule_ref = @{ shift; };
			splice( @rule_ref, 0, 1 );
			return \@rule_ref;
		},
	' '	=> sub {
			my @rule_ref = @{ shift; };
			splice( @rule_ref, 0, 1 );
			$this->{function_count}--;
			return \@rule_ref;
		},
	'l' => sub {
			my @rule_ref = @{ shift; };
			splice( @rule_ref, 0, 1 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			$this->{status}->{pos}{$_}->{case} = 'l' for 0 .. $largest_pos;
			return \@rule_ref;
		},
	'u' => sub {
			my @rule_ref = @{ shift; };
			splice( @rule_ref, 0, 1 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			$this->{status}->{pos}{$_}->{case} = 'u' for 0 .. $largest_pos;
			return \@rule_ref;
		},
	'c' => sub {
			my @rule_ref = @{ shift; };
			splice( @rule_ref, 0, 1 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			$this->{status}->{pos}{0}->{case} = 'u';
			$this->{status}->{pos}{$_}->{case} = 'l' for 1 .. $largest_pos;
			return \@rule_ref;
		},
	'C' => sub {
			my @rule_ref = @{ shift; };
			splice( @rule_ref, 0, 1 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			$this->{status}->{pos}{0}->{case} = 'l';
			for (1 .. $largest_pos) {
				if(exists($this->{status}->{pos}{$_})) {
					$this->{status}->{pos}{$_}->{case} = 'u';
				}
			}
			return \@rule_ref;
		},
	'r' => sub {
			my @rule_ref = @{ shift; };
			splice( @rule_ref, 0, 1 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			my $temp;
			for (0 .. $largest_pos) {
				$temp->{status}->{pos}{$_} = dclone $this->{status}->{pos}{$largest_pos - $_};
			}
			$this->{status}->{pos} = dclone $temp->{status}->{pos};
			return \@rule_ref;
		},
	't' => sub {
			my @rule_ref = @{ shift; };
			splice( @rule_ref, 0, 1 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			for (0 .. $largest_pos) {
				my $case = $this->{status}->{pos}{$_}->{case};
				$this->{status}->{pos}{$_}->{case} = $case eq 'd' ? 'b' : $case eq 'b' ? 'd' : $case eq 'l' ? 'u' : 'l';
			}
			return \@rule_ref;
		},
	'T' => sub {
			my @rule_ref = @{ shift; };
			my $pos = &to_pos( $rule_ref[1] );
			splice( @rule_ref, 0, 2 );
			if(exists($this->{status}->{pos}{$pos})) {
				my $case = $this->{status}->{pos}{$pos}->{case};
				$this->{status}->{pos}{$pos}->{case} = $case eq 'd' ? 'b' : $case eq 'b' ? 'd' : $case eq 'l' ? 'u' : 'l';
			}
			return \@rule_ref;
		},
	'd' => sub {
			my @rule_ref = @{ shift; };
			splice( @rule_ref, 0, 1 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			for (0 .. $largest_pos) {
				$this->{status}->{pos}{$largest_pos + 1 + $_} = dclone $this->{status}->{pos}{$_};
			}
			return \@rule_ref;
		},
	'p' => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			splice( @rule_ref, 0, 2 );
			for (0 .. $n) {
				my $largest_pos = &largest_pos( $this->{status}->{pos} );
				foreach my $pos (0 .. $largest_pos) {
					$this->{status}->{pos}{$largest_pos + 1 + $pos} = dclone $this->{status}->{pos}{$pos};
				}
			}
			return \@rule_ref;
		},
	'f' => sub {
			my @rule_ref = @{ shift; };
			splice( @rule_ref, 0, 1 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			for (0 .. $largest_pos) {
				$this->{status}->{pos}{$largest_pos + 1 + $_} = dclone $this->{status}->{pos}{$largest_pos - $_};
			}
			return \@rule_ref;
		},
	'{' => sub {
			my @rule_ref = @{ shift; };
			splice( @rule_ref, 0, 1 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			my $temp = dclone $this->{status}->{pos}{0};
			for (1 .. $largest_pos) {
				$this->{status}->{pos}{$_ - 1} = delete $this->{status}->{pos}{$_};
			}
			$this->{status}->{pos}{$largest_pos} = dclone $temp;
			return \@rule_ref;
		},
	'}' => sub {
			my @rule_ref = @{ shift; };
			splice( @rule_ref, 0, 1 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			my $temp = dclone $this->{status}->{pos}{$largest_pos};
			for (reverse 0 .. $largest_pos - 1) {
				if(exists($this->{status}->{pos}{$_})) {
					$this->{status}->{pos}{$_ + 1} = dclone $this->{status}->{pos}{$_};
				}
			}
			$this->{status}->{pos}{0} = dclone $temp;
			return \@rule_ref;
		},
	'$' => sub {
			my @rule_ref = @{ shift; };
			my $char = $rule_ref[1];
			splice( @rule_ref, 0, 2 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			if (exists $this->{status}->{deleted_chars}{$char}) {
				delete $this->{status}->{deleted_chars}{$char};
			}
			$this->{status}->{pos}{$largest_pos + 1}->{value} = lc($char);
			$this->{status}->{pos}{$largest_pos + 1}->{element} = -1;
			$this->{status}->{pos}{$largest_pos + 1}->{case} = &get_case( $char );
			$this->{status}->{pos}{$largest_pos + 1}->{bitwize_shift} = {'l' => 0, 'd' => 0, 'u' => 0};
			$this->{status}->{pos}{$largest_pos + 1}->{ascii_shift} = {'l' => 0, 'd' => 0, 'u' => 0};

			return \@rule_ref;
		},
	'^' => sub {
			my @rule_ref = @{ shift; };
			my $char = $rule_ref[1];
			splice( @rule_ref, 0, 2 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			if (exists $this->{status}->{deleted_chars}{$char}) {
				delete $this->{status}->{deleted_chars}{$char};
			}
			for (reverse 0 .. $largest_pos)	{
				$this->{status}->{pos}{$_ + 1} = dclone $this->{status}->{pos}{$_};
			}
			$this->{status}->{pos}{0}->{value} = lc($char);
			$this->{status}->{pos}{0}->{element} = -1;
			$this->{status}->{pos}{0}->{case} = &get_case( $char );
			$this->{status}->{pos}{0}->{bitwize_shift} = {'l' => 0, 'd' => 0, 'u' => 0};
			$this->{status}->{pos}{0}->{ascii_shift} = {'l' => 0, 'd' => 0, 'u' => 0};
			return \@rule_ref;
		},
	'[' => sub {
			my @rule_ref = @{ shift; };
			splice( @rule_ref, 0, 1 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			delete $this->{status}->{pos}{0}; # delete first element
			# backward positions by 1
			for (1 .. $largest_pos) {
				$this->{status}->{pos}{$_ - 1} = delete $this->{status}->{pos}{$_};
			}
			return \@rule_ref;
		},
	']' => sub {
			my @rule_ref = @{ shift; };
			splice( @rule_ref, 0, 1 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			delete $this->{status}->{pos}{$largest_pos}; # delete last element
			return \@rule_ref;
		},
	'D' => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			splice( @rule_ref, 0, 2 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			delete $this->{status}->{pos}{$n}; # delete element at position $n
			# backward positions by 1 after $n
			for ($n + 1 .. $largest_pos) {
				$this->{status}->{pos}{$_ - 1} = delete $this->{status}->{pos}{$_};
			}
			return \@rule_ref;
		},
	'x' => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			my $m = &to_pos( $rule_ref[2] );
			splice( @rule_ref, 0, 3 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			delete $this->{status}->{pos}{$_} for $m + $n .. $largest_pos; # delete element after $m
			delete $this->{status}->{pos}{$_} for 0 .. $n - 1; # delete element before $n
			# backward positions by $n
			for ($n .. $n + $m - 1) {
				if(exists($this->{status}->{pos}{$_})) {
					$this->{status}->{pos}{$_ - $n} = delete $this->{status}->{pos}{$_};
				}
			}
			return \@rule_ref;
		},
	'O' => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			my $m = &to_pos( $rule_ref[2] );
			splice( @rule_ref, 0, 3 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			delete $this->{status}->{pos}{$_} for $n .. $n + $m - 1; # delete range $n -> $m
			# backward positions
 			for ($n + $m .. $largest_pos) {
				$this->{status}->{pos}{$_ - $m} = delete $this->{status}->{pos}{$_};
			}
			return \@rule_ref;
		},
	'i' => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			my $char = $rule_ref[2];
			splice( @rule_ref, 0, 3 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if ($largest_pos == -1 || $n > $largest_pos);
			if (exists $this->{status}->{deleted_chars}{$char}) {
				delete $this->{status}->{deleted_chars}{$char};
			}
			# forwarding positions by 1
 			for (reverse $n .. $largest_pos) {
				$this->{status}->{pos}{$_ + 1} = delete $this->{status}->{pos}{$_};
			}
			$this->{status}->{pos}{$n}->{value} = lc($char);
			$this->{status}->{pos}{$n}->{element} = -1;
			$this->{status}->{pos}{$n}->{case} = &get_case( $char );
			$this->{status}->{pos}{$n}->{bitwize_shift} = {'l' => 0, 'd' => 0, 'u' => 0};
			$this->{status}->{pos}{$n}->{ascii_shift} = {'l' => 0, 'd' => 0, 'u' => 0};
			return \@rule_ref;
		},
	'o' => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			my $char = $rule_ref[2];
			splice( @rule_ref, 0, 3 );
			return \@rule_ref if &largest_pos( $this->{status}->{pos} ) == -1;
			if (exists $this->{status}->{deleted_chars}{$char}) {
				delete $this->{status}->{deleted_chars}{$char};
			}
			if(exists($this->{status}->{pos}{$n})) {
				$this->{status}->{pos}{$n}->{value} = lc($char);
				$this->{status}->{pos}{$n}->{element} = -1;
				$this->{status}->{pos}{$n}->{case} = &get_case( $char );
				$this->{status}->{pos}{$n}->{bitwize_shift} = {'l' => 0, 'd' => 0, 'u' => 0};
				$this->{status}->{pos}{$n}->{ascii_shift} = {'l' => 0, 'd' => 0, 'u' => 0};
			}
			return \@rule_ref;
		},
	"'" => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			splice( @rule_ref, 0, 2 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			# delete range $n -> last
			foreach my $pos ($n .. $largest_pos) {
				delete $this->{status}->{pos}{$pos};
			}
			# delete position in substitution
			foreach my $char (keys %{$this->{status}->{substitution}}) {
				foreach my $pos ($n .. $largest_pos) {
					delete $this->{status}->{substitution}{$char}{ascii_shift}{$pos};
					delete $this->{status}->{substitution}{$char}{bitwize_shift}{$pos};
					delete $this->{status}->{substitution}{$char}{case}{$pos};
				}
			}
			return \@rule_ref;
		},
	's' => sub {
			my @rule_ref = @{ shift; };
			my $char = $rule_ref[1];
			my $replaced_char = $rule_ref[2];
			my $replaced_char_case = &get_case( $replaced_char );
			splice( @rule_ref, 0, 3 );
			# change nothing if trying to replace character by itself
			return \@rule_ref if $char eq $replaced_char;
			return \@rule_ref if exists $this->{status}->{deleted_chars}{$char};
			$this->{status}->{deleted_chars}{$char} = 1;
			# if a character was deleted before, it shouldn't be replaced because it doesn't exists.
			return \@rule_ref if defined $this->{status}->{substitution}{$char} && $this->{status}->{substitution}{$char} eq '';
			$this->{status}->{substitution}{$char}{'c'} = $replaced_char;
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			for (0 .. $largest_pos) {
				if(exists($this->{status}->{pos}{$_})) {
					foreach my $key (qw/ascii_shift bitwize_shift/) {
						if(!($this->{status}->{pos}{$_}->{$key}{'l'} == 0
							&& $this->{status}->{pos}{$_}->{$key}{'d'} == 0
							&& $this->{status}->{pos}{$_}->{$key}{'u'} == 0)){
							$this->{status}->{substitution}{$char}{$key}{$_} = {
								'l' => $this->{status}->{pos}{$_}->{$key}{'l'},
								'd' => $this->{status}->{pos}{$_}->{$key}{'d'},
								'u' => $this->{status}->{pos}{$_}->{$key}{'u'}
							};
						}
					}
					if($this->{status}->{pos}{$_}->{case} ne 'd' && $this->{status}->{pos}{$_}->{value} eq '') {
						$this->{status}->{substitution}{$char}{'case'}{$_} = $this->{status}->{pos}{$_}->{case};
					}
					if ($this->{status}->{pos}{$_}->{value} eq $char && $this->{status}->{pos}{$_}->{case} eq $replaced_char_case &&
					($this->{status}->{pos}{$_}->{bitwize_shift}{'l'} == 0 && $this->{status}->{pos}{$_}->{bitwize_shift}{'d'} == 0 &&
					$this->{status}->{pos}{$_}->{bitwize_shift}{'u'} == 0 && $this->{status}->{pos}{$_}->{ascii_shift}{'l'} == 0 &&
					$this->{status}->{pos}{$_}->{ascii_shift}{'d'} == 0 && $this->{status}->{pos}{$_}->{ascii_shift}{'u'} == 0)) {
						$this->{status}->{pos}{$_}->{value} = $replaced_char;
						$this->{status}->{pos}{$_}->{element} = -1;
						$this->{status}->{pos}{$_}->{case} = $replaced_char_case;
						$this->{status}->{pos}{$_}->{bitwize_shift} = {'l' => 0, 'd' => 0, 'u' => 0};
						$this->{status}->{pos}{$_}->{ascii_shift} = {'l' => 0, 'd' => 0, 'u' => 0};

					}
				}
			}
			return \@rule_ref;
		},
		'@' => sub {
				my @rule_ref = @{ shift; };
				my $char = $rule_ref[1];
				splice( @rule_ref, 0, 2 );
				# add to deleted_chars chars
				if (exists $this->{status}->{deleted_chars}{$char}) {
					return \@rule_ref;
				} else {
					$this->{status}->{deleted_chars}{$char} = 1;
				}
				# replace $char with '' ( blank )
				my $replaced_char = '';
				# if a character is replaced by $char, it should be replace by ''
				if(defined $this->{status}->{substitution}) {
					my $tmp = dclone $this->{status}->{substitution};
				 	while (my ($key, $replaced_by) = each %{$tmp}) {
						if($replaced_by->{'c'} eq $char) {
							$this->{status}->{substitution}{$key}{'c'} = $replaced_char;
						}
					}
				}
				my $largest_pos = &largest_pos( $this->{status}->{pos} );
				$this->{status}->{substitution}{$char}{'c'} = $replaced_char;
				# delete character if exists
				return \@rule_ref if $largest_pos == -1;
				foreach my $pos (0 .. $largest_pos) {
					if(exists($this->{status}->{pos}{$pos}) &&
						$this->{status}->{pos}{$pos}->{value} eq $char) {
						for ($pos + 1 .. $largest_pos) {
							$this->{status}->{pos}{$_ - 1} = delete $this->{status}->{pos}{$_};
						}
					}
					if(exists($this->{status}->{pos}{$pos})) {
						foreach my $key (qw/ascii_shift bitwize_shift/) {
							if(!($this->{status}->{pos}{$pos}->{$key}{'l'} == 0
								&& $this->{status}->{pos}{$pos}->{$key}{'d'} == 0
								&& $this->{status}->{pos}{$pos}->{$key}{'u'} == 0)){
								$this->{status}->{substitution}{$char}{$key}{$pos} = {
									'l' => $this->{status}->{pos}{$pos}->{$key}{'l'},
									'd' => $this->{status}->{pos}{$pos}->{$key}{'d'},
									'u' => $this->{status}->{pos}{$pos}->{$key}{'u'}
								};
							}
						}
						if($this->{status}->{pos}{$pos}->{case} ne 'd') {
							$this->{status}->{substitution}{$char}{'case'}{$pos} = $this->{status}->{pos}{$pos}->{case};
						}
					}
				}
				return \@rule_ref;
	},
	'z' => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			splice( @rule_ref, 0, 2 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			# forward positions by $n
			for (reverse 1 .. $largest_pos) {
				$this->{status}->{pos}{$_ + $n} = delete $this->{status}->{pos}{$_};
			}
			# duplicate first char
			if(exists($this->{status}->{pos}{0})) {
				for (1 .. $n) {
					$this->{status}->{pos}{$_} = dclone $this->{status}->{pos}{0};
				}
			}
			return \@rule_ref;
		},
	'Z' => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			splice( @rule_ref, 0, 2 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			# duplicate first char
			if(exists($this->{status}->{pos}{$largest_pos})) {
				for ($largest_pos + 1 .. $largest_pos + $n) {
					$this->{status}->{pos}{$_} = dclone $this->{status}->{pos}{$largest_pos};
				}
			}
			return \@rule_ref;
		},
	'q' => sub {
			my @rule_ref = @{ shift; };
			splice( @rule_ref, 0, 1 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			for (reverse 0 .. $largest_pos) {
				$this->{status}->{pos}{$_ + $_ + 1} = dclone $this->{status}->{pos}{$_};
				$this->{status}->{pos}{$_ + $_} = dclone $this->{status}->{pos}{$_};
			}
			return \@rule_ref;
		},

	# Specific
	'k' => sub {
			my @rule_ref = @{ shift; };
			splice( @rule_ref, 0, 1 );
			return \@rule_ref if &largest_pos( $this->{status}->{pos} ) == -1;
			if(exists($this->{status}->{pos}{0}) && exists($this->{status}->{pos}{1})) {
				($this->{status}->{pos}{0}, $this->{status}->{pos}{1}) = ($this->{status}->{pos}{1}, $this->{status}->{pos}{0});
			}
			return \@rule_ref;
		},
	'K' => sub {
			my @rule_ref = @{ shift; };
			splice( @rule_ref, 0, 1 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			if(exists($this->{status}->{pos}{$largest_pos}) && exists($this->{status}->{pos}{$largest_pos - 1})) {
				($this->{status}->{pos}{$largest_pos}, $this->{status}->{pos}{$largest_pos - 1}) = ($this->{status}->{pos}{$largest_pos - 1}, $this->{status}->{pos}{$largest_pos});
			}
			return \@rule_ref;
		},
	'*' => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			my $m = &to_pos( $rule_ref[2] );
			splice( @rule_ref, 0, 3 );
			return \@rule_ref if &largest_pos( $this->{status}->{pos} ) == -1;
			if(exists($this->{status}->{pos}{$n}) && exists($this->{status}->{pos}{$m})) {
				($this->{status}->{pos}{$n}, $this->{status}->{pos}{$m}) = ($this->{status}->{pos}{$m}, $this->{status}->{pos}{$n});
			}
			return \@rule_ref;
		},
	'L' => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			splice( @rule_ref, 0, 2 );
			return \@rule_ref if &largest_pos( $this->{status}->{pos} ) == -1;
			if(exists($this->{status}->{pos}{$n})) {
				if($this->{status}->{pos}{$n}->{value} eq '') {
					# $this->{status}->{pos}{$n}->{bitwize_shift}++;
					$this->{status}->{pos}{$n}->{bitwize_shift}{$this->{status}->{pos}{$n}->{case}}++;
				} else {
					$this->{status}->{pos}{$n}->{value} = chr( ord( $this->{status}->{pos}{$n}->{value} ) << 1 );
				}
			}
			return \@rule_ref;
		},
	'R' => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			splice( @rule_ref, 0, 2 );
			return \@rule_ref if &largest_pos( $this->{status}->{pos} ) == -1;
			if(exists($this->{status}->{pos}{$n})) {
				if($this->{status}->{pos}{$n}->{value} eq '') {
					$this->{status}->{pos}{$n}->{bitwize_shift}{$this->{status}->{pos}{$n}->{case}}--;
				} else {
					$this->{status}->{pos}{$n}->{value} = chr( ord( $this->{status}->{pos}{$n}->{value} ) >> 1 );
					# $this->{status}->{pos}{$n}->{case} = &get_case( $this->{status}->{pos}{$n}->{value} );
				}
			}
			return \@rule_ref;
		},
	'+' => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			splice( @rule_ref, 0, 2 );
			return \@rule_ref if &largest_pos( $this->{status}->{pos} ) == -1;
			if(exists($this->{status}->{pos}{$n})) {
				if($this->{status}->{pos}{$n}->{value} eq '') {
					$this->{status}->{pos}{$n}->{ascii_shift}{$this->{status}->{pos}{$n}->{case}}++;
				} else {
					$this->{status}->{pos}{$n}->{value} = chr( ord( $this->{status}->{pos}{$n}->{value} ) + 1 );
				}
			}
			return \@rule_ref;
		},
	'-' => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			splice( @rule_ref, 0, 2 );
			return \@rule_ref if &largest_pos( $this->{status}->{pos} ) == -1;
			if(exists($this->{status}->{pos}{$n})) {
				if($this->{status}->{pos}{$n}->{value} eq '') {
					$this->{status}->{pos}{$n}->{ascii_shift}{$this->{status}->{pos}{$n}->{case}}--;
				} else {
					$this->{status}->{pos}{$n}->{value} = chr( ord( $this->{status}->{pos}{$n}->{value} ) - 1 );
				}
			}
			return \@rule_ref;
		},
	'.' => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			splice( @rule_ref, 0, 2 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			if(exists($this->{status}->{pos}{$n}) && exists($this->{status}->{pos}{$n + 1})) {
				$this->{status}->{pos}{$n} = dclone $this->{status}->{pos}{$n + 1};
			}
			return \@rule_ref;
		},
	',' => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			splice( @rule_ref, 0, 2 );
			return \@rule_ref if &largest_pos( $this->{status}->{pos} ) == -1;
			if(exists($this->{status}->{pos}{$n}) && exists($this->{status}->{pos}{$n - 1})) {
				$this->{status}->{pos}{$n} = dclone $this->{status}->{pos}{$n - 1};
			}
			return \@rule_ref;
		},
	'y' => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			splice( @rule_ref, 0, 2 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			return \@rule_ref if $n > $largest_pos + 1;
			# forward all positions by $n
			for (reverse 0 .. $largest_pos) {
				if(exists($this->{status}->{pos}{$_})) {
					$this->{status}->{pos}{$_ + $n} = delete $this->{status}->{pos}{$_};
				}
			}
			for (0 .. $n - 1) {
				if(exists($this->{status}->{pos}{$_ + $n})) {
					$this->{status}->{pos}{$_} = dclone $this->{status}->{pos}{$_ + $n};
				}
			}
			return \@rule_ref;
		},
	'Y' => sub {
			my @rule_ref = @{ shift; };
			my $n = &to_pos( $rule_ref[1] );
			splice( @rule_ref, 0, 2 );
			my $largest_pos = &largest_pos( $this->{status}->{pos} );
			return \@rule_ref if $largest_pos == -1;
			return \@rule_ref if $n > $largest_pos + 1;
			for (reverse $largest_pos - $n + 1 .. $largest_pos) {
				if(exists($this->{status}->{pos}{$_})) {
					$this->{status}->{pos}{$_ + $n} = dclone $this->{status}->{pos}{$_};
				}
			}
			return \@rule_ref;
		},

	};
	return $this;
}

sub proccess {
	my $self = shift;
	my $rule = shift;
	my @return;
	my $i = 0;
	foreach my $magic (0 .. $self->{magic}) {
		$self->{function_count} = 0;
		# initialize
		$self->{status}->{pos}{$_}->{case} = 'd' for 0 .. $magic;
		$self->{status}->{pos}{$_}->{element} = $_ + 1 for 0 .. $magic;
		$self->{status}->{pos}{$_}->{value} = '' for 0 .. $magic;
		$self->{status}->{pos}{$_}->{bitwize_shift} = {'l' => 0, 'u' => 0, 'd' => 0} for 0 .. $magic; # left -> + | right -> -
		$self->{status}->{pos}{$_}->{ascii_shift} = {'l' => 0, 'u' => 0, 'd' => 0} for 0 .. $magic; # left -> + | right -> -
		# $self->{status}->{substitution};
		# $this->{status}->{deleted_chars}
		$self->{last_element} = $magic + 1; # used when inserting new elements to keep counting.
		# finish initialization
		my $rule_ref = [ split '', $rule ];
		while (1) {
			last if !@{$rule_ref}[0];
			print "Executing @{$rule_ref}[0]: \n" if $self->{verbose};
			$rule_ref =	$self->{rules}->{ @{$rule_ref}[0] }->( $rule_ref );
			$self->{function_count}++;
			print Dumper $self->{status} if $self->{verbose};
		}
		$return[$i++] = $self->{status};
		$self->{status} = undef;
	}
	return wantarray() ? (\@return, $self->{function_count}) : \@return;
};

sub to_pos {
	my $pos = $_[0];
	if ( $pos =~ /\d/ ) { return $pos; }
	return 10 + ord($pos) - 65;
}

sub largest_pos {
	my $hash   = shift;
	my @keys = keys %$hash;
	my $max = -1;
	foreach my $key (0 .. $#keys) {
		$max = $keys[$key] if $keys[$key] > $max;
	}
	return $max;
}

sub get_case {
	my $char = shift; # length = 1
	# return $char =~ /^\p{Uppercase}+$/ ? 'u' : 'l';
	return lc($char) eq $char ? 'l' : 'u';
}

1;
# (c) mhasbini 2016
package Utils;
use strict;
use warnings;
use Data::Dumper;
use Digest::MD5 qw/md5_hex/;
use utf8;
use Encode;

sub new {
	my $class = shift;
	my %parm  = @_;
	my $this  = {};
	bless $this, $class;
	return $this;
}

sub generate_id {
	my $self = shift;
	my @status = @{ shift; };
	my $str = '';
	foreach my $status (@status) {
		my %pos = %{ $status->{pos} };
		foreach my $pos (sort {$a <=> $b} keys %pos) {
			$str .= $pos;
			$str .= $pos{$pos}->{ascii_shift}{'l'};
			$str .= $pos{$pos}->{ascii_shift}{'u'};
			$str .= $pos{$pos}->{ascii_shift}{'d'};
			$str .= $pos{$pos}->{bitwize_shift}{'l'};
			$str .= $pos{$pos}->{bitwize_shift}->{'u'};
			$str .= $pos{$pos}->{bitwize_shift}->{'d'};
			$str .= $pos{$pos}->{case};
			$str .= $pos{$pos}->{element};
			$str .= $pos{$pos}->{value};
		}
		if(defined $status->{deleted_chars}) {
			foreach my $key (sort keys %{$status->{deleted_chars}}) {
				$str .= "deleted_key:$key";
			}
		}
		if (defined $status->{substitution}) {
			my %substitution = %{ $status->{substitution} };
			foreach my $key (sort keys %substitution) {
				$str .= $key.$substitution{$key}{'c'};
				foreach my $s_key (qw/ascii_shift bitwize_shift/) {
					foreach my $n (sort {$a <=> $b} keys %{$substitution{$key}{$s_key}}) {
						$str .= $substitution{$key}{$s_key}{$n}{'l'};
						$str .= $substitution{$key}{$s_key}{$n}{'u'};
						$str .= $substitution{$key}{$s_key}{$n}{'d'};
					}
				}
				foreach my $n (sort {$a <=> $b} keys %{$substitution{$key}{'case'}}) {
					$str .= $substitution{$key}{'case'}{$n};
				}
			}
		}
	}
	return md5_hex(utf8::is_utf8($str) ? Encode::encode_utf8($str) : $str);
}

sub is_supported {
	my $self = shift;
	my $rule = shift;
	my $validate_regex = q!\*[0-9A-Za-z][0-9A-Za-z]|x[0-9A-Za-z][0-9A-Za-z]|i[0-9A-Za-z].|O[0-9A-Za-z][0-9A-Za-z]|o[0-9A-Za-z].|s..|L[0-9A-Za-z]|R[0-9A-Za-z]|\+[0-9A-Za-z]|-[0-9A-Za-z]|\.[0-9A-Za-z]|,[0-9A-Za-z]|y[0-9A-Za-z]|Y[0-9A-Za-z]|T[0-9A-Za-z]|p[0-9A-Za-z]|D[0-9A-Za-z]|'[0-9A-Za-z]|z[0-9A-Za-z]|Z[0-9A-Za-z]|\$.|\^.|\@.|:|l|u|c|C|t|r|d|f|{|}|\[|\]|q|k|K|\s!;
	$rule =~ s/$validate_regex//g;
	return length($rule) == 0 ? 1 : 0;
}

1;
use strict;
use warnings;
use Getopt::Std;

my %args;
getopts('o:h', \%args);

if (defined $args{h}) {
	print qq{Usage: perl $0 [options] < input_rules > uniq_rules
	options:
		-o\t optional\t file to write duplicate rules to
		-h\t optional\t print this help message};
	exit 0;
}

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


if (defined $args{o}) {
	open my $out, '>', $args{o} or die $!;
	flock $out, 2; # lock file
	foreach my $dup (@{$duplicates}) {
		print $out join(', ', @{$dup}), "\n";
	}
	close $out; # unlock and close
}

foreach my $rule (@{$uniq}) {
	print $rule, "\n";
}
