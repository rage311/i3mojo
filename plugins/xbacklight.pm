package xbacklight;

use Mojo::Base 'i3Mojo::Plugin::Base', -signatures;
use i3Mojo::Util;

use constant BIN => 'xbacklight';
use constant SYS => [ BIN, qw( -steps 1 -time 0 )];

use constant ADJ => {
  MOUSE_DOWN() => '-10',
  MOUSE_UP()   => '+10',
};

sub status ($self) {
  return 'err' unless open my $xbacklight, '-|', BIN;

  chomp(my $level = <$xbacklight>);
  close $xbacklight;

  return defined $level ? int($level) . '%' : '?';
}

sub click ($self, $button) {
  system SYS->@*, ADJ->{$button};
}

1;

