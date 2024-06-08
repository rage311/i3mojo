package weather_pirate;

use Mojo::Base 'i3Mojo::Plugin::Base', -signatures;
use i3Mojo::Util;
use Carp 'croak';

use Mojo::UserAgent;

use constant SECONDS_PER_DAY => 86_400;
use constant ICONS => {
  'clear-day'           => '',
  'clear-night'         => '',
  'rain'                => '',
  'snow'                => '',
  'sleet'               => '',
  'wind'                => '',
  'fog'                 => '',
  'cloudy'              => '',
  'partly-cloudy-day'   => '',
  'partly-cloudy-night' => '',
};

# can be changed with config
has unit        => 'F';
has unit_preset => 'us';
has lat         => 40.5;
has long        => -90.5;
has api_key     => sub { croak 'api_key is required' };

sub status ($self) {
  my $time = time;
  my $res = Mojo::UserAgent->new->get(
    'https://api.pirateweather.net/forecast'
      . '/' . $self->api_key
      . '/' . $self->lat
      . ',' . $self->long,
    form => { exclude => join ',', qw/ minutely hourly alerts flags /
  })->res;

  croak 'Error in response from pirateweather API' unless
    $res && (my $json = $res->json);

  my $today = $json->{daily}{data}[0];
  my ($day_high, $day_low) = $today->@{qw/ temperatureHigh temperatureLow /};
  my $current = $json->{currently};

  return sprintf '%s %d%s (%d/%d)',
    ICONS->{$current->{icon}} // $current->{summary},
    $current->{temperature},
    $self->unit,
    int($day_low),
    int($day_high);
}

sub click ($self, $button) {
  system 'xdg-open',
    'https://merrysky.net/forecast/'
      . $self->lat
      . ','
      . $self->long
      . '/'
      . $self->unit_preset;

  return 1;
}

1;

