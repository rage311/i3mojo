package pulseaudio;

use Mojo::Base 'i3Mojo::Plugin::Base', -signatures;
use i3Mojo::Util;
use Carp 'croak';

use constant VOLUME_ICONS => [
  '', # fa-volume-off  [&#xf026;]
  '', # fa-volume-down [&#xf027;]
  '', # fa-volume-up   [&#xf028;]
];

# separate because mute can't be scaled like the volume levels
use constant VOLUME_ICONS_MUTE => ''; #f6a9 fa-volume-mute

has amount    => 5;
has device    => 'Master';
has mixer_cmd => sub { [qw/ alacritty -e pulsemixer /] };

sub status_volume ($self) {
  #return ('on', 100);
  my $device = $self->device;
  return unless my $volume = qx(/usr/bin/amixer -D pulse get $device);
  return ($2, $1) if $volume =~ /\[(\d+)%\] \[(.+)\]/;
  return ('?', -1);
}

sub status ($self) {
  my ($status, $volume) = $self->status_volume;
  croak unless $status && defined $volume;

  return (VOLUME_ICONS_MUTE, PRIORITY_URGENT) if $status eq 'off';

  my $icon = VOLUME_ICONS->[
    scale_nearest_int(
      raw     => $volume,
      raw_min => 0,
      raw_max => 100,
      eng_min => 0,
      eng_max => $#{VOLUME_ICONS()}
    )];

  return ("$icon $volume%", $volume > 100 ? PRIORITY_URGENT : PRIORITY_NORMAL);
}

sub click ($self, $button) {
  my ($status, $volume) = $self->status_volume;

  my $dispatch = {
    MOUSE_LEFT() => sub {
      system('/usr/bin/pactl', 'set-sink-mute', '@DEFAULT_SINK@', 'toggle');
    },
    MOUSE_RIGHT() => sub {
      system(qw( /usr/bin/i3-msg -q -- exec ), $self->mixer_cmd->@*);
    },
    MOUSE_UP() => sub {
      my $round_volume = int(($volume + 5) / 5) * 5;
      system('/usr/bin/pactl', 'set-sink-volume', '@DEFAULT_SINK@', "$round_volume%");
    },
    MOUSE_DOWN() => sub {
      my $round_volume = int(($volume - 1) / 5) * 5;
      system('/usr/bin/pactl', 'set-sink-volume', '@DEFAULT_SINK@', "$round_volume%");
    },
  };

  return 1 unless defined $button && defined $dispatch->{$button};

  # Handle mouse button input
  $dispatch->{$button}->();

  return 1;
}

1;

