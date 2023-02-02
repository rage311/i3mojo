package solaar;

use Mojo::Base 'i3Mojo::Plugin::Base', -signatures;
use i3Mojo::Util;
use Carp 'croak';

# can be changed with config
has 'device_string';

sub status ($self) {
  my $lines = slurp_stdout('/usr/bin/solaar show ' . $self->device_string);
  my ($batt_pct) = $lines =~ /Battery:\s*(\d+)%/;
  return "$batt_pct%";
}

sub click ($self, $button) {
  return 1;
}

1;

