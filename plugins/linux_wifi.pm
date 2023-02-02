package linux_wifi;

use Mojo::Base 'i3Mojo::Plugin::Base', -signatures;
use Mojo::Util qw(dumper trim);

use Carp 'croak';

use constant ICON_NO_CONN => '';

# can be changed with config in ->new() call
has device => 'wlan0';

sub status ($self) {
  my $device = $self->device;

  open my $iw_fh, '-|', "/usr/bin/env iw dev $device link"
    or croak "$!";
  my @iw_output = <$iw_fh>;
  close $iw_fh;

  say dumper \@iw_output if $ENV{DEBUG};

  my $conn_str = shift @iw_output;
  say $conn_str if $ENV{DEBUG};

  # Strange connection string
  return undef unless
    $conn_str
    && $conn_str =~ /Connected to [a-f0-9:]{17} \(on [a-z0-9]{3,}\)|Not connected\./;

  return ICON_NO_CONN() if $conn_str =~ /Not connected\./;

  # turn key: value strings into hash keys and values, skipping blank lines
  my %stats = map { map { trim $_ } split /:/ } grep { /[\S]/ } @iw_output;

  return undef unless
    %stats
    && $conn_str =~ /Connected to (?<mac>[a-f0-9:]{17}) \(on (?<dev>[a-z0-9]{3,})\)/;

  $stats{AP_MAC} = $+{mac};
  $stats{dev}    = $+{dev};
  ($stats{signal_int}) = $stats{signal} =~ /\s*(-\d{1,3})/;
  $stats{signal_pct} = -100 < $stats{signal_int} <= -50
    ? 2 * ($stats{signal_int} + 100)
    : $stats{signal_int} > -50
      ? 100
      : 0;

  return "$stats{SSID} $stats{signal_pct}%";
}

sub click ($self, $button) { 1 }

1;

