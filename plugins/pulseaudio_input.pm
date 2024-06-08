package pulseaudio_input;

use Mojo::Base 'i3Mojo::Plugin::Base', -signatures;
use i3Mojo::Util;
use Carp 'croak';

# pulsemixer --list-sources
#has source_id => 'source-51';
sub default_source_id {
  my @sources =  split /\n/, (qx/ pulsemixer --list-sources /);
  croak 'error: unable to find default source' unless
    my $default_source = (grep { /Default/ } @sources)[0];

  # Source:		 ID: source-10150, Name: Starship/Matisse HD Audio Controller Analog Stereo, Mute: 0, Channels: 2, Volumes: ['32%', '32%'], Default
  croak 'error: unexpected pulsemixer output' unless
    $default_source =~ /Source:\s+ID:\s+(?<source_id>[^,]+),\s+Name/;

  return $+{source_id};
}

sub status ($self) {
  my $source_id = default_source_id();
  my $muted = qx/ pulsemixer --get-mute --id $source_id /;
  return $muted == 1 ? '' : (' ', PRIORITY_URGENT);
}

sub click ($self, $button) {
  system("pulsemixer --toggle-mute --id " . default_source_id());
  return 1;
}

1;

