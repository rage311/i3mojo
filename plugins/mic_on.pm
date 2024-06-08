package mic_on;

use Mojo::Base 'i3Mojo::Plugin::Base', -signatures;
use i3Mojo::Util;
use Carp 'croak';

# can be changed with config
# has instance_attr => 'unique';

sub status ($self) {
  # system('arecord -f S16_LE -r 44100 -c2 -D hw:1,0 -d 1 --quiet >/dev/null 2>&1');
  open my $sox_stdout,
    '-|',
    'arecord -f S16_LE -r 44100 -c2 -D hw:1,0 -d 1 --quiet | sox -t .wav - -n stats 2>&1'
    or die "$!";
  my @sox_output = <$sox_stdout>;
  close $sox_stdout;

  my $ff_overall;
  for my $line (@sox_output) {
    next unless $line =~ /Flat factor\s+(?<ff_overall>[\w\s]+)/;
    chomp($ff_overall = $+{ff_overall});
  }
  my $mic_on = $ff_overall < 5.0;

  return $mic_on ? ('', PRIORITY_URGENT) : '';
}

sub click ($self, $button) {
  return 1;
}

1;

