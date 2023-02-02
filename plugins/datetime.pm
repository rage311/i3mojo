package datetime;

use Mojo::Base 'i3Mojo::Plugin::Base', -signatures;

use DateTime;

# default format: Thu 04/22 17:53
has format   => '%a %m/%d %H:%M';
has timezone => 'UTC';

sub status ($self) {
  DateTime->now()
    ->set_time_zone($self->timezone)
    ->strftime($self->format);
}

1;

