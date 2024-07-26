package linux_battery;

use Mojo::Base 'i3Mojo::Plugin::Base', -signatures;
use i3Mojo::Util;
use Mojo::File;
use Mojo::Util qw/dumper trim/;
use Carp 'croak';

use constant {
  BATTERY_ICONS => {
    Charging       => '',#"\x{f1e6}", # fa-plug
    Discharging    => '',
    Full           => '',#"\x{f1e6}", # fa-plug
    'Not charging' => '',
    Unknown        => '?',
    BATTERY        => [
      '', # fa-battery-0 (alias) [&#xf244;]
      '', # fa-battery-1 (alias) [&#xf243;]
      '', # fa-battery-2 (alias) [&#xf242;]
      '', # fa-battery-3 (alias) [&#xf241;]
      '', # fa-battery-4 (alias) [&#xf240;]
    ],
  },
};

# can be changed with config in ->new() call
has low      => 20;
has low_low  => 10;
has sys_path => '/sys/class/power_supply/BAT0';

# files in /sys/class/power_supply/BATX:
#   capacity (% charge)
#   charge_full (mA ?)
#   charge_now (mA ?)
#   status (string -- "Discharging", ... assuming same options as acpi?)

sub status ($self) {
  my $path = Mojo::File->new($self->sys_path);
  my $batt = {
    status       => trim($path->child('status')->slurp),
    percent      => trim($path->child('capacity')->slurp),
    charge       => trim($path->child('charge_now')->slurp),
    current      => trim($path->child('current_now')->slurp),
    time_to_dest => '0:00',
  };

  my $time_to_dest_hours = $batt->{charge} / $batt->{current};
  my $time_to_dest_minutes = int(
    ($time_to_dest_hours - int $time_to_dest_hours) * 60
  );
  $batt->{time_to_dest} =
    int($time_to_dest_hours)
    . ':'
    . sprintf '%02d', $time_to_dest_minutes;

  my $charging = $batt->{status} ne 'Discharging'
    && $batt->{status} ne 'Unknown';
  my $icon = BATTERY_ICONS->{$batt->{status}} . ' ' // '';

  my $icon_idx = scale_nearest_int(
    raw     => $batt->{percent},
    raw_min => 0,
    raw_max => 100,
    eng_min => 0,
    eng_max => $#{BATTERY_ICONS->{BATTERY}}
  );

  $icon .= BATTERY_ICONS->{BATTERY}[$icon_idx];

  my $return_string = "$icon $batt->{percent}%";
  $return_string .= " ($batt->{time_to_dest})"
    if !$charging;

  my $priority = $charging
    ? PRIORITY_NORMAL
    : $batt->{percent} <= $self->low_low
      ? PRIORITY_URGENT
      : $batt->{percent} <= $self->low
        ? PRIORITY_IMPORTANT
        : undef;

  return ($return_string, $priority);
}

sub click ($self, $button) {
  return 1;
}

1;

#say __PACKAGE__->new()->status();
