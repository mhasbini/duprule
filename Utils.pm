# (c) mhasbini 2016
package Utils;
use strict;
use warnings;
use Data::Dumper;
use Digest::MD5 qw/md5_hex/;

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
			$str .= $pos{$pos}->{ascii_shift};
			$str .= $pos{$pos}->{bitwize_shift};
			$str .= $pos{$pos}->{case};
			$str .= $pos{$pos}->{element};
			$str .= $pos{$pos}->{value};
		}
		if (defined $status->{substitution}) {
			my %substitution = %{ $status->{substitution} };
			foreach my $key (sort keys %substitution) {
				$str .= $key.$substitution{$key};
			}
		}
	}
	return md5_hex($str);
}

1;
