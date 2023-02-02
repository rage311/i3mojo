package disk_usage;

use Mojo::Base 'i3Mojo::Plugin::Base', -signatures;

use i3Mojo::Util;
use Mojo::Util 'dumper';

# can be changed with config in ->new() call
has mount => '/';

has thresholds => sub {
  state $thresholds = {
    PRIORITY_URGENT    => 95,
    PRIORITY_IMPORTANT => 90,
  }
};

sub df ($self) {
  my $dir = $self->mount;
  my $df = qx(df -h $dir);

  return unless
    (scalar (my @df_lines = split/\n/, $df) == 2)
    && index($df, 'No such file or directory') == -1;

  return unless
    my @df_fields = map { s/\s+$//r } $df_lines[0] =~ /([A-Z][^A-Z]+)/g;

  say dumper @df_fields if $ENV{DEBUG};

  return unless
    my @df_values = split /\s+/, $df_lines[1];

  return unless $#df_fields == $#df_values;

  my %df_hash = map { $df_fields[$_] => $df_values[$_] } 0..$#df_fields;
  say dumper \%df_hash if $ENV{DEBUG};

  return \%df_hash;
}

sub status ($self) {
  return ('err', PRIORITY_URGENT) unless
    my $df_hash = $self->df;

  return ('err', PRIORITY_URGENT) unless
    my $cap_pct = ($df_hash->{Capacity} // $df_hash->{'Use%'});

  $cap_pct =~ s/%//;

  my $color = $cap_pct >= $self->thresholds->{PRIORITY_URGENT}
    ? PRIORITY_URGENT    : $cap_pct >= $self->thresholds->{PRIORITY_IMPORTANT}
    ? PRIORITY_IMPORTANT : PRIORITY_NORMAL;

  return ($df_hash->{Avail} // 'err', $color);
}

1;

