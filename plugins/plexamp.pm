package plexamp;

use Mojo::Base 'i3Mojo::Plugin::Base', -signatures;
use i3Mojo::Util;
use Carp 'croak';

use Mojo::Util 'dumper';

use Mojo::UserAgent;

use constant ICON_PLAYBACK => {
  paused   => '',
  playing  => '',
  stopped  => '',
};

# "Player->title" in the plex API
has player_name => 'unique';
has url_base    => 'http://127.0.0.1:32400';
has _ua         => sub { state $ua = Mojo::UserAgent->new; };

sub status ($self) {
  my $sessions = $self->_ua->get($self->url_base . '/status/sessions')
    ->result
    ->dom
    ->xml(1);

  my $track = shift $sessions
    ->find('Track')
    ->grep(sub ($track) { $track->at('Player')->{title} eq $self->player_name })
    ->@*;

  # no matching session
  return () unless $track;

  my $player = $track->at('Player');

  # state can be at least: playing, paused
  return
    ICON_PLAYBACK->{$player->{state}}
    . ' '
    . $track->{grandparentTitle}
    . ' - '
    . $track->{title};
}

sub click ($self, $button) {
  return 1;
}

1;

