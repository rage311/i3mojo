package i3Mojo::Util;

use Mojo::Base -strict, -signatures;

use Exporter 'import';

our @EXPORT = qw(
  scale_nearest
  scale_nearest_int
  slurp_stdout

  MOUSE_LEFT
  MOUSE_MIDDLE
  MOUSE_RIGHT
  MOUSE_UP
  MOUSE_DOWN

  PRIORITY_NORMAL
  PRIORITY_IMPORTANT
  PRIORITY_URGENT
  PRIORITY_CRITICAL
);

use constant MOUSE_LEFT   => 1;
use constant MOUSE_MIDDLE => 2;
use constant MOUSE_RIGHT  => 3;
use constant MOUSE_UP     => 4;
use constant MOUSE_DOWN   => 5;

use constant PRIORITY_NORMAL    => 0;
use constant PRIORITY_IMPORTANT => 1;
use constant PRIORITY_URGENT    => 2;
use constant PRIORITY_CRITICAL  => 3;

sub scale_nearest_int (%params) {
  my $scaled = int(
      ($params{raw}     - $params{raw_min})
    * ($params{eng_max} + 1 - $params{eng_min})
    / ($params{raw_max} - $params{raw_min})
    +  $params{eng_min}
  );

  return $scaled > $params{eng_max} ? $params{eng_max} : $scaled;
}

sub scale_nearest (%params) {
  return sprintf('%.0f',
      ($params{raw}     - $params{raw_min})
    * ($params{eng_max} - $params{eng_min})
    / ($params{raw_max} - $params{raw_min})
    +  $params{eng_min}
  );
}

sub slurp_stdout ($command) {
  local $/;
  open my $fh, '-|', $command;
  my $output = <$fh>;
  close $fh;
  return $output;
}

1;

