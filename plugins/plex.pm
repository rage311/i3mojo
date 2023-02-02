package plex;

use Mojo::Base 'i3Mojo::Plugin::Base', -signatures;
use i3Mojo::Util;
use Carp 'croak';

use Mojo::UserAgent;

has url_base => sub ($, $url) {
  croak 'Invalid URL' unless Mojo::URL->new($url);
};

has 'server_id';

sub status ($self) {
  my $ua = Mojo::UserAgent->new;
  my $res = $ua->get($self->url_base . '/status/sessions')->result;

  return unless my $media = $res->dom->at("MediaContainer");

  my $streams = $media->attr('size');
  my $video   = $res->dom->xml(1)->at('MediaContainer > Video');

  return unless $streams && $video;

  my $user    = $video->at('User')->attr('title');
  my $v_title = $video->attr('grandparentTitle')
    ? $video->attr('grandparentTitle') . ' - ' . $video->attr('title')
    : $video->attr('title');
  my $v_year  = $video->attr('year');

  # add thumbnail
  my $v_thumb_path = $video->attr('thumb');
  $ua->get($self->url_base . $v_thumb_path)
    ->result
    ->content
    ->asset
    ->move_to('/tmp/m_asset.jpg');

  my $stat_file = Mojo::File->new('/tmp', 'plex_status.xml');
  my $curr_stat = $video->attr('key') . "\n" . $video->at('User');
  my $prev_stat = -f "$stat_file" ? $stat_file->slurp : '';

  system(qw( /usr/bin/notify-send -i /tmp/m_asset.jpg ), $user, "$v_title\n")
    if $prev_stat ne $curr_stat;

  $stat_file->spurt($curr_stat);

  return $streams ? ($streams, PRIORITY_IMPORTANT) : $streams;
}

sub click ($self, $button) {
  system('xdg-open',
    $self->url_base
    . '/web/index.html#!/settings/server/'
    . $self->server_id
    . '/status/server-dashboard'
  ) if $button == MOUSE_LEFT;
}

1;

