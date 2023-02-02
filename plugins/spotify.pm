package spotify;

use Mojo::Base 'i3Mojo::Plugin::Base', -signatures;
use i3Mojo::Util;
use Carp 'croak';
use Mojo::Util 'decode';

use Net::DBus;

use constant ICON_PLAYBACK => {
  Paused   => '',
  Playing  => '',
  Stopped  => '',
};


sub status ($self) {
  return unless qx(pidof -s spotify);
  my $bus = Net::DBus->session;

  my $spotify_service = $bus->get_service('org.mpris.MediaPlayer2.spotify');
  my $mpris_object    = $spotify_service->get_object('/org/mpris/MediaPlayer2');
  my $playback_status = $mpris_object->Get('org.mpris.MediaPlayer2.Player', 'PlaybackStatus');
  my $metadata        = $mpris_object->Get('org.mpris.MediaPlayer2.Player', 'Metadata');

  return unless $spotify_service
    && $mpris_object
    && $playback_status
    && $metadata;

  # decode seems necessary since it was somehow getting double encoded as UTF-8
  return ICON_PLAYBACK->{$playback_status}
    . decode('UTF-8', "  $metadata->{'xesam:artist'}[0] - $metadata->{'xesam:title'}");
}

sub click ($self, $button) {
  my $dispatch = {
    MOUSE_UP()    => sub { system('/usr/bin/playerctl', '-p', 'spotify', 'next') },
    MOUSE_DOWN()  => sub { system('/usr/bin/playerctl', '-p', 'spotify', 'previous') },
    MOUSE_LEFT()  => sub { system('/usr/bin/playerctl', '-p', 'spotify', 'play-pause') },
    MOUSE_RIGHT() => sub {
      system(q{/usr/bin/i3-msg '[instance="spotify"]' focus >/dev/null 2>&1})
    },
  };

  $dispatch->{$button}->() if $dispatch->{$button};
}

1;

