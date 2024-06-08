package weather;

use Mojo::Base 'i3Mojo::Plugin::Base', -signatures;
use i3Mojo::Util;
use Carp 'croak';

use Mojo::UserAgent;

use constant ICONS => {
  '01d' => '',  # f185 fas fa-sun
  '01n' => '',  # f186 fas fa-moon
  '02d' => '',  # f6c4 fas fa-cloud-sun
  '02n' => '',  # f6c3 fas fa-cloud-moon
  '03d' => '',  # f0c2 fas fa-cloud
  '03n' => '',  # f0c2 fas fa-cloud
  '04d' => '',  # f0c2 fas fa-cloud
  '04n' => '',  # f0c2 fas fa-cloud
  '09d' => '',  # f0e9 fas fa-umbrella
  '09n' => '',  # f0e9 fas fa-umbrella
  '10d' => '',  # f0e9 fas fa-umbrella
  '10n' => '',  # f0e9 fas fa-umbrella
  '11d' => '',  # f0e7 fas fa-bolt
  '11n' => '',  # f0e7 fas fa-bolt
  '13d' => '',  # f2dc fas fa-snowflake
  '13n' => '',  # f2dc fas fa-snowflake
  '50d' => '',  #
  '50n' => '',  #
};


# can be changed with config
has unit    => 'F';
has lat     => 40.5;
has long    => -90.5;
has api_key => sub { croak 'api_key is required' };

sub status ($self) {
  my $ua = Mojo::UserAgent->new;

  my $daily = $ua->get(
    'https://api.openweathermap.org/data/2.5/forecast/daily',
    form => {
      lat   => $self->lat,
      lon   => $self->long,
      appid => $self->api_key,
      units => 'imperial',
      cnt   => 1,
    }
  )->result;

  my $current = $ua->get(
    'https://api.openweathermap.org/data/2.5/weather',
    form => {
      lat     => $self->lat,
      lon     => $self->long,
      appid   => $self->api_key,
      units   => 'imperial',
      exclude => join ',', qw( minutely hourly alerts )
    }
  )->result;

  croak 'Error in response from openweather API' unless
    $daily && (my $json = $daily->json);

  my $current_json = $current->json;
  my $current_temp = $current_json->{main}{temp};
  my $current_weather = $current_json->{weather}[0];

  my ($day_min, $day_max) = $daily->json->{list}[0]{temp}->@{qw( min max )};

  return sprintf '%s %d%s (%d/%d)',
    ICONS->{$current_weather->{icon}} // $current_weather->{main},
    $current_temp,
    $self->unit,
    int($day_min),
    int($day_max);
}


sub click ($self, $button) {
  system 'xdg-open', 'https://openweathermap.org/';
  return 1;
}

1;

