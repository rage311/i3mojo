package linux_battery;

use Mojo::Base 'i3Mojo::Plugin::Base', -signatures;
use i3Mojo::Util;
use Mojo::File;
use Mojo::Util qw/dumper trim/;
use Carp 'croak';

use constant {
  BATTERY_ICONS => {
    #CHARGING => '', # fa-flash
    Charging    => '',#"\x{f1e6}", # fa-plug
    Full        => '',#"\x{f1e6}", # fa-plug
    Discharging => '',
    Unknown  => '?',
    BATTERY  => [
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
has sys_path => '/sys/class/power_supply/BAT1';

# files:
#   capacity (% charge)
#   charge_full (mA ?)
#   charge_now (mA ?)
#   status (string -- "Discharging", ... assuming same options as acpi?)

sub status ($self) {
  my $path = Mojo::File->new($self->sys_path);
  my $batt = {
    status  => trim $path->child('status')->slurp,
    percent => trim $path->child('capacity')->slurp,
    charge  => trim $path->child('charge_now')->slurp,
  };

  say dumper $batt;
}

#Battery 0: Unknown, 99%

sub status_acpi ($self) {
  open my $acpi_fh, '-|', '/usr/bin/env acpi -b'; # args here?
  my $acpi_output = trim <$acpi_fh>;
  close $acpi_fh;

  # Battery 0: Full, 100%
  # Battery 0: Discharging, 77%, 08:48:06 remaining
  my ($batt_id, $batt_status, $batt_pct, $batt_hh, $batt_mm, $batt_ss) = $acpi_output =~ /
    Battery \s+ (\d+): \s+
    (Discharging|Charging|Full|Unknown), \s+
    (\d+)%
    (?: , \s+ 0*([0-9]{1,}):([0-9]{2}):([0-9]{2}))?
  /x;

  my $charging = $batt_status ne 'Discharging'
    && $batt_status ne 'Unknown';
  my $icon = BATTERY_ICONS->{$batt_status} . ' ' // '';

  my $icon_idx = scale_nearest_int(
    raw     => $batt_pct,
    raw_min => 0,
    raw_max => 100,
    eng_min => 0,
    eng_max => $#{BATTERY_ICONS->{BATTERY}}
  );

  $icon .= BATTERY_ICONS->{BATTERY}[$icon_idx];

  my $return_string = "$icon $batt_pct%";
  $return_string .= " ($batt_hh:$batt_mm)" if defined $batt_hh && defined $batt_mm;

  my $priority = $charging
    ? PRIORITY_NORMAL
    : $batt_pct <= $self->low_low
      ? PRIORITY_URGENT
      : $batt_pct <= $self->low
        ? PRIORITY_IMPORTANT
        : undef;

  return ($return_string, $priority);
}

sub click ($self, $button) {
  return 1;
}

1;

say __PACKAGE__->new()->status();
