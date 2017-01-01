use Data::Dumper;

our @libs = glob 'lib/*.pm';
push @libs, 'main.pl';

my $out = 'duprule.pl';

our @packages = ('FindBin', 'lib');

# grep packages
execute_on_libs (
  sub {
    my $line = shift;
    if ($line =~ /package\s+(.*?);/) {
      push @packages, $1;
    }});

open my $fh, '>', $out or die $!;

# merge into $out execluding `use $package` in @packages
execute_on_libs (
  sub {
    my $line = shift;
    if ($line =~ /use\s+(.*?);/) {
      unless (grep {$1 =~ $_} @packages) {
        print $fh $line;
      }
    } else {
      print $fh $line;
    }});

close $fh;
print Dumper \@packages;

sub execute_on_libs {
  my $fn = shift;
  foreach my $lib (@libs) {
    open my $in, '<', $lib or die $!;
    while (my $line = <$in>) {
      $fn->($line);
    }
    close $in;
  }
}

# pod documentation here
