package freebsd_volume;

use Mojo::Base 'i3Mojo::Plugin::Base', -signatures;
#use i3Mojo::Util;
#use Carp 'croak';

# can be changed with config
#has instance_attr => 'unique';

sub status ($self) {
  my $vol_line = qx{ /usr/sbin/mixer vol };
  return 'err' unless $vol_line =~ /:(\d+)$/;
  my $vol_pct_int = $1;

  return "$vol_pct_int%";
}

sub click ($self, $button) {
  return 1;
}

1;

