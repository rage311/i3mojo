package bittrex;

use Mojo::Base 'i3Mojo::Plugin::Base', -signatures;
use i3Mojo::Util;

use Mojo::UserAgent;

use constant BASE_URL => sub ($market) { "https://api.bittrex.com/v3/markets/${market}/ticker" };

# can be changed with config in ->new() call
has market => 'BTC-USDT';

sub status ($self) {
  my $res = Mojo::UserAgent->new->get(BASE_URL->($self->market))->result;

  return ('err', PRIORITY_URGENT) unless
    $res
    && $res->is_success
    && $res->json
    && (my $mkt_val = int($res->json->{lastTradeRate}));

  return "\$$mkt_val";
}

sub click ($self, $button) {
  return 1;
}

1;

