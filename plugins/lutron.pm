package lutron;

use Mojo::Base 'i3Mojo::Plugin::Base', -signatures;
use i3Mojo::Util;
use Mojo::Util 'decode';
use Carp 'croak';
use lib '$HOME/dev/lutron/lib/';
use Lutron::Caseta;

has bridge_host => sub { croak 'lutron bridge_host not defined' };
has bridge_port => 8081;
has zones       => sub { (1) };

has caseta => sub ($self) {
  state $caseta = Lutron::Caseta->new(
    host => $self->bridge_host,
    port => $self->bridge_port,
  );
};

sub listen ($self, $subprocess) {
  while (1) {
    local $| = 1;
    $self->caseta->status($_) for $self->zones;

    $self->caseta->on(zone_status => sub ($self, $status) {
      $subprocess->progress($status->{zone} . ':' . $status->{level} . '%');
    });
    $self->caseta->listen;

    $subprocess->progress('err', PRIORITY_CRITICAL);
    sleep 1;
  }
}

sub click ($self, $button) {
  my $dispatch = {
    MOUSE_LEFT() => sub {
      $self->caseta->set_level(
        ZONE() => $self->caseta->levels->{ZONE()} > 0 ? 0 : 100
      );
    },
    MOUSE_UP() => sub {
      $self->caseta->set_level(
        ZONE() => int((($self->caseta->levels->{ZONE()} // 0) + 5) / 5) * 5
      );
    },
    MOUSE_DOWN() => sub {
      $self->caseta->set_level(
        ZONE() => int((($self->caseta->levels->{ZONE()} // 0) - 1) / 5) * 5
      );
    },
  };

  $dispatch->{$button}->() if defined $dispatch->{$button};
}

1;

