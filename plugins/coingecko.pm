package coingecko;

use Mojo::Base 'i3Mojo::Plugin::Base', -signatures;
use i3Mojo::Util;

use Mojo::UserAgent;

use constant BASE_URL => 'https://api.coingecko.com/api/v3/simple/price';

has coin            => 'bitcoin';
has currency        => 'usd';
has currency_symbol => '$';

sub status ($self) {
  my $res = Mojo::UserAgent->new->get(
    BASE_URL(),
    form => {
      ids           => $self->coin,
      vs_currencies => $self->currency
    })->result;

  return ('err', PRIORITY_URGENT) unless
    $res
    && $res->is_success
    && $res->json
    && (my $mkt_val = $res->json->{$self->coin}{$self->currency});

  return $self->currency_symbol . $mkt_val;
}

sub click ($self, $button) {
  system('xdg-open', 'https://www.coingecko.com/en/coins/' . $self->coin);
  return 1;
}

1;

