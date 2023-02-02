package openbsd_snapshot;

use Mojo::Base 'i3Mojo::Plugin::Base', -signatures;

use Carp 'croak';
use DateTime;
use Mojo::UserAgent;
use Mojo::Util 'dumper';

use constant URL_CDN_AMD64 =>
  'https://cdn.openbsd.org/pub/OpenBSD/snapshots/amd64';

use constant M2N => {qw(
  Jan 1
  Feb 2
  Mar 3
  Apr 4
  May 5
  Jun 6
  Jul 7
  Aug 8
  Sep 9
  Oct 10
  Nov 11
  Dec 12
)};


has ua       => sub { Mojo::UserAgent->new };
has url_base => sub { URL_CDN_AMD64 };

sub status ($self) {
  # example output:
  # OpenBSD 6.5-current (GENERIC.MP) #53: Fri Jun 21 16:41:06 MDT 2019
  #   deraadt@amd64.openbsd.org:/usr/src/sys/arch/amd64/compile/GENERIC.MP
  my $openbsd_ver = qx{ /sbin/sysctl -n kern.version };

  return 'error' unless
    $openbsd_ver =~
      m/
        OpenBSD \s
        (?<version>[\d\.\-\w]+).+
        #(?<build>\d+):\s+
        (?<dow>\w+)\s+
        (?<mon>\w+)\s+
        (?<day>\d+)\s+
        (?<hr>\d+):
        (?<min>\d+):
        (?<sec>\d+)\s+
        (?<tz>\w+)\s+
        (?<year>\d+)
      /x;

  my $local_tz = DateTime::TimeZone->new(name => 'local');

  my $running_dt = DateTime->new(
    year      => $+{year},
    month     => M2N->{$+{mon}},
    day       => $+{day},
    hour      => int($+{hr}),
    minute    => $+{min},
    second    => $+{sec},
    time_zone => $local_tz,
  ) or return 'error';

  my $remote_modified = $self->ua->get($self->url_base . '/BUILDINFO')
    ->result
    ->content
    ->asset
    ->to_file
    ->slurp;

  return 'error' unless $remote_modified =~ /^Build date: (?<epoch>\d+) -/;

  my $remote_dt = DateTime->from_epoch(epoch => $+{epoch}) or die "$!";

  my $diff_days = $remote_dt
    ->delta_days($running_dt->clone->set_time_zone('UTC'))
    ->in_units('days');

  return $diff_days > 0
    ? "+${diff_days}d ("
      . ($diff_days < 90 ? $remote_dt->strftime('%m/%d') : $remote_dt->ymd('/'))
      . ')'
    : ''; # check mark
}

sub click ($self, $button) {
  system '/usr/bin/env xdg-open \'' . $self->url_base . '\'';
}

1;

