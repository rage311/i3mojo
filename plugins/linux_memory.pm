package linux_memory;

use Mojo::Base 'i3Mojo::Plugin::Base', -signatures;
use i3Mojo::Util;
use Carp 'croak';

sub status ($self) {
  my $lines = slurp_stdout('/usr/bin/free -m');

  my ($total, $used, $free, $shared, $buf, $avail) =
    $lines =~ /Mem:\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/;

  my $avail_g = sprintf '%.1fG', $avail/1024;
  return $avail / $total < 0.10 ? ($avail_g, PRIORITY_CRITICAL) : $avail_g;
}

1;

