package syncthing;

use Mojo::Base 'i3Mojo::Plugin::Base', -signatures;
use i3Mojo::Util;
use Carp 'croak';

# can be changed with config
has api_key    => sub { croak 'api_key required' };
has executable => sub { croak 'executable required' };
has folder     => 'default';
has host       => '127.0.0.1';
has port       => 8384;
has secure     => 0;

# apiKey :: !BS.ByteString,
# host   :: !Text,
# secure :: !Bool,
# port'  :: !Int,
# folder :: !Text,
# debug  :: !Bool

sub status ($self) {
  my $command = join ' ',
    $self->executable,
    '--api-key'   , $self->api_key,
    '--folder'    , $self->folder,
    '--host'      , $self->host,
    '--port'      , $self->port,
    $self->secure ? '--secure' : ();

  chomp(my $status = slurp_stdout $command);

  return $status;
}

sub click ($self, $button) {
  return 1;
}

1;

