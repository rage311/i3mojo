package linux_cpu_usage;

use Mojo::Base 'i3Mojo::Plugin::Base', -signatures;
use i3Mojo::Util;
use Carp 'croak';

# can be changed with config
has important => 50;
has urgent    => 80;

sub status ($self) {
  # if mpstat is not run under en_US locale, things may break, so make sure it is
  $ENV{LC_ALL} = "en_US";

  my $cpu_usage;

  open my $mpstat, '-|', 'mpstat 1 1';
  while (<$mpstat>) {
    next unless /^.*\s+(\d+\.\d+)\s+$/;
    $cpu_usage = 100 - $1; # 100% - %idle
    last;
  }
  close $mpstat;

  croak "Can't find CPU information" unless defined $cpu_usage;

  my $priority = $cpu_usage >= $self->urgent
    ? PRIORITY_URGENT
    : $cpu_usage >= $self->important
      ? PRIORITY_IMPORTANT
      : PRIORITY_NORMAL;

  return (sprintf('%02d%%', $cpu_usage), $priority)
}

sub click ($self, $button) {
  return 1;
}

1;

__DATA__
Linux 5.4.13-arch1-1 (r9-arch) 	01/23/2020 	_x86_64_	(32 CPU)

09:34:08 PM  CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
09:34:09 PM  all    0.06    0.00    0.06    0.00    0.03    0.00    0.00    0.00    0.00   99.84
Average:     all    0.06    0.00    0.06    0.00    0.03    0.00    0.00    0.00    0.00   99.84

