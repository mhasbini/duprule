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

sub is_supported {
	my $self = shift;
	my $rule = shift;
	my $validate_regex = q!\*[0-9A-Za-z][0-9A-Za-z]|x[0-9A-Za-z][0-9A-Za-z]|i[0-9A-Za-z].|O[0-9A-Za-z][0-9A-Za-z]|o[0-9A-Za-z][0-9A-Za-z]|s..|L[0-9A-Za-z]|R[0-9A-Za-z]|\+[0-9A-Za-z]|-[0-9A-Za-z]|\.[0-9A-Za-z]|,[0-9A-Za-z]|y[0-9A-Za-z]|Y[0-9A-Za-z]|T[0-9A-Za-z]|p[0-9A-Za-z]|D[0-9A-Za-z]|'[0-9A-Za-z]|z[0-9A-Za-z]|Z[0-9A-Za-z]|\$.|\^.|\@.|:|l|u|c|C|t|r|d|f|{|}|\[|\]|q|k|K|\s!;
	$rule =~ s/$validate_regex//g;
	return length($rule) == 0 ? 1 : 0;
}

1;
