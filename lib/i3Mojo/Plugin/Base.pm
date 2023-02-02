package i3Mojo::Plugin::Base;

use Mojo::Base -base, -signatures;
use Carp 'croak';

has 'config';

sub click ($self, $button) {
  return 1;
}

sub status ($self) {
  croak 'Method "status" not implemented by subclass';
}

1;

