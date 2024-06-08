package backlight_light;

use Mojo::Base 'i3Mojo::Plugin::Base', -signatures;
use i3Mojo::Util;

use constant BIN => 'light';

use constant FLAG => {
  MOUSE_DOWN() => '-U',
  MOUSE_UP()   => '-A',
};

has amount => 2;

sub status ($self) {
  return 'err' unless open
    my $light, '-|', BIN;

  chomp(my $level = <$light>);
  close $light;

  return defined $level ? int($level) . '%' : '?';
}

sub click ($self, $button) {
  return 1 unless defined FLAG->{$button};
  system BIN(), FLAG->{$button}, $self->amount;
}

1;

