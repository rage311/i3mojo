package openbsd_wifi;

use Mojo::Base 'i3Mojo::Plugin::Base', -signatures;
use Mojo::Util 'dumper';

use Carp 'croak';

use constant ICON_NO_CONN => '';

# can be changed with config in ->new() call
has device => 'iwm0';

sub status ($self) {
  my $device = $self->device;

  # read output from ifconfig
  open my $ifconfig_fh, '-|', "/sbin/ifconfig $device" or croak "$!";
  my @ifconfig_input = <$ifconfig_fh>;
  close $ifconfig_fh;

  my $wifi_status;
  for my $line (@ifconfig_input) {
    next unless $line =~ /status:\s+(?<wifi_status>[\w\s]+)/;
    chomp($wifi_status = $+{wifi_status});
  }
  return ICON_NO_CONN() if $wifi_status && $wifi_status ne 'active';

  my %current_wifi;
  while ((my $line = shift @ifconfig_input) && ! %current_wifi) {
    # look for current wifi line
    next unless $line =~ /^\s*ieee80211: (?<wifi_details>.+)$/;

    die 'Unable to parse current wifi details' . dumper($line)
      unless $+{wifi_details} =~ m{
        ^ (nwid|join)  \s  "? (?<nwid>[^"]+) "?       \s
          chan         \s     (?<chan>\d+)            \s
          bssid        \s     (?<bssid>[\da-f:]+)     \s?
                              ((?<signal_pct>\d+)%)?
      }x;

    %current_wifi = %+;
  }

  return undef unless %current_wifi;

  return $current_wifi{signal_pct} && $wifi_status eq 'active'
    ? "$current_wifi{nwid} $current_wifi{signal_pct}%"
    : ICON_NO_CONN() . ' ' . $current_wifi{nwid};
}

sub click ($self, $button) { 1 }

1;

