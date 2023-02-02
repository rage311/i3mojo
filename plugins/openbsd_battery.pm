package openbsd_battery;

use Mojo::Base 'i3Mojo::Plugin::Base', -signatures;
use i3Mojo::Util;
use Carp 'croak';

use constant {
  APM_CHARGER => {
    DISCONNECTED => 0,
    CONNECTED    => 1,
    BACKUP       => 2,
    UNKNOWN      => 255,

    0   => 'disconnected',
    1   => 'connected',
    2   => 'backup power source',
    255 => 'unknown',
  },

  APM_BATTERY => {
    HIGH     => 0,
    LOW      => 1,
    CRITICAL => 2,
    CHARGING => 3,
    ABSENT   => 4,
    UNKNOWN  => 255,

    0   => 'high',
    1   => 'low',
    2   => 'critical',
    3   => 'charging',
    4   => 'absent',
    255 => 'unknown',
  },

  BATTERY_STATUS_ICONS => {
    3   => '', # charging -- fa-flash ... check CHARGER == 'connected' && BATTERY == 'charging'
    255 => '?',
  },

  BATTERY_ICONS => {
    #CHARGING => '', # fa-flash
    #CHARGING => '', # fa-plug
    CHARGING => "\x{f1e6}", # fa-plug
    UNKNOWN  => '?',
    BATTERY  => [
      '', # fa-battery-0 (alias) [&#xf244;]
      '', # fa-battery-1 (alias) [&#xf243;]
      '', # fa-battery-2 (alias) [&#xf242;]
      '', # fa-battery-3 (alias) [&#xf241;]
      '', # fa-battery-4 (alias) [&#xf240;]
    ],
  },
};

use constant APM_IOC_GETPOWER => 0x40204103;

use constant APM_POWER_INFO   => [
  { battery_state => 'C'   },
  { ac_state      => 'C'   },
  { battery_life  => 'C'   },
  { spare1        => 'A'   },
  { minutes_left  => 'L'   },
  { spare2        => 'A24' },
];


# can be changed with config in ->new() call
has low           => 20;
has low_low       => 10;


sub apm_ioc_getpower ($self) {
  croak "Unable to open /dev/apm: $!" unless
    open my $apm_fh, '<', '/dev/apm';

  my $apm_power_info_raw = '';
  my $ret = ioctl($apm_fh, APM_IOC_GETPOWER, $apm_power_info_raw) || -1;
  close $apm_fh;
  croak 'APM_IOC_GETPOWER ioctl failed' unless $ret;

  my $unpack_string = join ' ', map { (each(%$_))[1] } APM_POWER_INFO->@*;

  my @unpacked = unpack $unpack_string, $apm_power_info_raw;

  return { map {
    (keys APM_POWER_INFO->[$_]->%*)[0] => $unpacked[$_]
  } 0 .. $#unpacked };
}

sub battery_known ($battery_state) {
  return
    $battery_state    != APM_BATTERY->{ABSENT}
    && $battery_state != APM_BATTERY->{UNKNOWN}
}

sub status ($self) {
  my $power = $self->apm_ioc_getpower();

  my $icon = $power->{ac_state} == APM_CHARGER->{CONNECTED}
    ? BATTERY_ICONS->{CHARGING} . ' '
    : '';

  if (battery_known($power->{battery_state})) {
    my $icon_idx = scale_nearest_int(
      raw     => $power->{battery_life},
      raw_min => 0,
      raw_max => 100,
      eng_min => 0,
      eng_max => $#{BATTERY_ICONS->{BATTERY}}
    );

    $icon .= BATTERY_ICONS->{BATTERY}[$icon_idx];
  }

  my $return_string = "$icon " . (
      defined $power->{battery_life}
        ? "$power->{battery_life}%"
        : ''
    );

  # 32-bit uint max means "unknown" for battery minutes left
  $return_string .=
    $power->{minutes_left} =~ /^\d+$/ && $power->{minutes_left} < 0xFFFFFFFF
      ? sprintf ' (%d:%02d)', $power->{minutes_left} / 60, $power->{minutes_left} % 60
      : '';

  my $priority = $power->{ac_state} == APM_CHARGER->{CONNECTED}
    ? PRIORITY_NORMAL
    : $power->{battery_life} <= $self->low_low
      ? PRIORITY_URGENT
      : $power->{battery_life} <= $self->low
        ? PRIORITY_IMPORTANT
        : undef;

  return ($return_string, $priority);
}

sub click ($self, $button) {
  return 1;
}

1;

