package openbsd_volume;

use Mojo::Base 'i3Mojo::Plugin::Base', -signatures;

use i3Mojo::Util;
use Math::Round ':all';

use constant VOLUME_ICONS => [
  '', # fa-volume-off  [&#xf026;]
  '', # fa-volume-down [&#xf027;]
  '', # fa-volume-up   [&#xf028;]
];

# separate because mute can't be scaled like the volume levels
use constant VOLUME_ICONS_MUTE => ''; #f6a9 fa-volume-mute

# can be changed with config in ->new() call
has amount => 5;
has device => 'output';

# TODO: use this
# sub volume ($self) {
#   return unless
#     (my $current_vol) = qx(/usr/bin/mixerctl -n outputs.$device) =~ /^(\d+),/;
#   return $current_vol;
# }

sub status ($self) {
  my $device = $self->device;

  return (VOLUME_ICONS_MUTE, PRIORITY_URGENT) if
    index(qx(/usr/bin/sndioctl -n output.mute), '1') != -1;

  chomp(my $volume = qx(/usr/bin/sndioctl -n output.level));
  $volume = $1 if $volume =~ /^(\d(\.\d+)?)/;

  my $volume_pct = scale_nearest(
    raw     => $volume,
    raw_min => 0,
    raw_max => 1,
    eng_min => 0,
    eng_max => 100
  );

  my $icon = VOLUME_ICONS->[
    scale_nearest_int(
      raw     => $volume,
      raw_min => 0,
      raw_max => 1,
      eng_min => 0,
      eng_max => $#{VOLUME_ICONS()}
    )];

  return ("$icon $volume_pct%", PRIORITY_NORMAL);
}

sub click ($self, $button) {
  my $device = $self->device;
  my $amount = $self->amount;

  my $dispatch = {
    MOUSE_LEFT() => sub { adjust(0, $device) }, # mute
    MOUSE_UP()   => sub { adjust($amount, $device) },
    MOUSE_DOWN() => sub { adjust(-1 * $amount, $device) },
  };

  $dispatch->{$button}->();
}

sub adjust ($amount, $device) {
  return system '/usr/bin/sndioctl output.mute=! >/dev/null 2>&1'
    if $amount == 0;

  return unless
    (my $current_vol) = qx(/usr/bin/sndioctl -n output.level) =~ /^(\d(\.\d+)?)/;

  return if
    ($amount > 0 && $current_vol == 1) || ($amount < 0 && $current_vol == 0);

  my $new_vol = $amount > 0
    ? nhimult(0.05, $current_vol + 0.01)
    : nlowmult(0.05, $current_vol - 0.01);

  return system "/usr/bin/sndioctl output.level=$new_vol >/dev/null 2>&1";
}

1;

