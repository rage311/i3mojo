package pipe_balm;

# For reading status and priority text from a named pipe
# Format of input:
# status text, newline, [PRIORITY_TEXT], 2x newline, e.g.:
# "hello, this is my status\nPRIORITY_URGENT\n\n"

use Mojo::Base 'i3Mojo::Plugin::Base', -signatures;
use i3Mojo::Util;
use Carp 'croak';

use Mojo::Util qw/ decode trim /;
use POSIX 'mkfifo';

has path => sub { croak 'path must be defined' };

sub listen ($self, $subprocess) {
  local $/ = "\n\n";

  while (1) {
    if (-e $self->path && ! -p $self->path) {
      croak "Pipe " . $self->path . " exists and is not a pipe.";
    }

    if (! -p $self->path) {
      croak "Unable to create pipe " . $self->path . ". $!"
        unless
        mkfifo $self->path, 0666;
    }

    croak "Unable to open pipe " . $self->path . ". $!"
      unless
      open my $pipe, '<', $self->path;

    while (chomp(my $input = <$pipe>)) {
      my ($text, $priority_text) = split /\n/, $input;
      my $priority = PRIORITY_NORMAL;
      {
        no strict 'refs';
        $priority = eval { (trim $priority_text)->() } // $priority;
      }

      $subprocess->progress(decode('UTF-8', $text), $priority);
    }

    sleep 1;
  }

  # TODO: restart process if it fails
  # $subprocess->progress('err', PRIORITY_CRITICAL);
  # close $pipe;

  return 'empty';
}

sub click ($self, $button) {
  return 1;
}

1;

