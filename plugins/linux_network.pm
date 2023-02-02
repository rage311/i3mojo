package linux_network;

use Mojo::Base 'i3Mojo::Plugin::Base', -signatures;
use i3Mojo::Util;
use Carp 'croak';

has 'interface';

sub status ($self) {
  if (!$self->interface) {
    my $lines =  slurp_stdout '/usr/bin/ip route';
    croak 'No interface specified and no default route found from ip route'
      unless $lines =~ /default via \S+ dev (\S+)/;
    $self->interface($1);
  }

  croak 'Error running ip addr command' unless 
    open my $ip_fh, '-|', '/usr/bin/ip addr show ' . $self->interface;

  my $lines = do { local $/; <$ip_fh> };
  return $lines =~ /inet ([^ \/]+).* scope global/ ? $1 : 'None';
}

1;

