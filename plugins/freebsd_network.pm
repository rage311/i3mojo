package freebsd_network;

use Mojo::Base 'i3Mojo::Plugin::Base', -signatures;
use i3Mojo::Util;
use Carp 'croak';

# can be changed with config
has nic => sub { croak 'nic config variable is required' };

sub status ($self) {
  my $nic = $self->nic;
  my $ifconfig_output = qx{ /sbin/ifconfig $nic };
  return 'err' unless $ifconfig_output =~ /inet\s+(.+)\s+netmask/;
  my $ip_addr = $1;

  return $ip_addr;
}

sub click ($self, $button) {
  return 1;
}

1;

