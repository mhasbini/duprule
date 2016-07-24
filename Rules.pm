# (c) mhasbini 2016
package Rules;
use strict;
use warnings;
use vars qw($VERSION);
use constant MAGIC => 3; # TODO: 52
use Data::Dumper;
$VERSION = '0.01';


sub new {
    my $class = shift;
    my %parm  = @_;
    my $this  = {};
    bless $this, $class;
    $this->{verbose} = $parm{verbose} || 0;
	# $this->{pos}{0} = {}
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
            return \@rule_ref;
		},
	'l' => sub {
            my @rule_ref = @{ shift; };
            splice( @rule_ref, 0, 1 );
			$this->{status}->{pos}{$_}->{case} = 'l' for 0 .. MAGIC;
			return \@rule_ref;
		},
	'u' => sub {
            my @rule_ref = @{ shift; };
            splice( @rule_ref, 0, 1 );
			$this->{status}->{pos}{$_}->{case} = 'u' for 0 .. MAGIC;
			return \@rule_ref;
		},
	'c' => sub {
            my @rule_ref = @{ shift; };
            splice( @rule_ref, 0, 1 );
			$this->{status}->{pos}{0}->{case} = 'u';
			$this->{status}->{pos}{$_}->{case} = 'l' for 1 .. MAGIC;
			return \@rule_ref;
		},
	'C' => sub {
            my @rule_ref = @{ shift; };
            splice( @rule_ref, 0, 1 );
			$this->{status}->{pos}{0}->{case} = 'l';
			$this->{status}->{pos}{$_}->{case} = 'u' for 1 .. MAGIC;
			return \@rule_ref;
		},
	'r' => sub {
            my @rule_ref = @{ shift; };
            splice( @rule_ref, 0, 1 );
			$this->{status}->{pos}{$_}->{pos} = MAGIC - $this->{status}->{pos}{$_}->{pos} for 0 .. MAGIC;
			return \@rule_ref;
		},
	't' => sub {
            my @rule_ref = @{ shift; };
            splice( @rule_ref, 0, 1 );
			for (0 .. MAGIC) {
				my $case = $this->{status}->{pos}{$_}->{case};
				$this->{status}->{pos}{$_}->{case} = $case eq 'd' ? 'b' : $case eq 'b' ? 'd' : $case eq 'l' ? 'u' : 'l';
			}
			return \@rule_ref;
		},
	'T' => sub {
            my @rule_ref = @{ shift; };
            my $pos = &to_pos( $rule_ref[1] );
            splice( @rule_ref, 0, 2 );
			my $case = $this->{status}->{pos}{$pos}->{case};
			$this->{status}->{pos}{$pos}->{case} = $case eq 'd' ? 'b' : $case eq 'b' ? 'd' : $case eq 'l' ? 'u' : 'l';
            return \@rule_ref;
        },

	};
	return $this;
}

sub proccess {
	my $self = shift;
	my $rule = shift;
	$self->{status}->{pos}{$_}->{case} = 'd' for 0 .. MAGIC;
	$self->{status}->{pos}{$_}->{pos} = $_ for 0 .. MAGIC;
	my $rule_ref = [ split '', $rule ];
	while (1) {
		last if !@{$rule_ref}[0];
		print "Executing @{$rule_ref}[0]: \n" if $self->{verbose};
		$rule_ref =	$self->{rules}->{ @{$rule_ref}[0] }->( $rule_ref );
	}
	my $return = $self->{status};
	$self->{status} = undef;
	return $return;
};

sub to_pos {
    my $pos = $_[0];
    if ( $pos =~ /\d/ ) { return $pos; }
    return 10 + ord($pos) - 65;
}

1;