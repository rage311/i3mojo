package spotify_external;

use Mojo::Base 'i3Mojo::Plugin::Base', -signatures;
use i3Mojo::Util;
use Mojo::Util 'decode';
use Carp 'croak';

has 'executable';

sub listen ($self, $subprocess) {
  while (1) {
    open my $stdout, '-|', $self->executable;

    while (chomp(my $line = <$stdout>)) {
      $subprocess->progress(decode 'UTF-8', $line);
    }

    # TODO: restart process if it fails
    $subprocess->progress('err', PRIORITY_CRITICAL);
    close $stdout;
    sleep 1;
  }
}

sub click ($self, $button) {
  my $dispatch = {
    MOUSE_UP()    => sub { system('/usr/bin/playerctl', '-p', 'spotify', 'next') },
    MOUSE_DOWN()  => sub { system('/usr/bin/playerctl', '-p', 'spotify', 'previous') },
    MOUSE_LEFT()  => sub { system('/usr/bin/playerctl', '-p', 'spotify', 'play-pause') },
    MOUSE_RIGHT() => sub { system(q{/usr/bin/i3-msg '[instance="spotify"]' focus >/dev/null 2>&1}) },
  };

  $dispatch->{$button}->() if $dispatch->{$button};
}

1;

