package package_name;

use Mojo::Base 'i3Mojo::Plugin::Base', -signatures;
use i3Mojo::Util;
use Carp 'croak';

# can be changed with config
has instance_attr => 'unique';

sub status ($self) {
  return 'empty';
}

sub click ($self, $button) {
  return 1;
}

1;

