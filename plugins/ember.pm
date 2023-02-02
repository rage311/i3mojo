package ember;

use Mojo::Base 'i3Mojo::Plugin::Base', -signatures;
use i3Mojo::Util;
use Carp 'croak';
use Mojo::UserAgent;
use Time::Piece;
use Mojo::JSON qw( encode_json decode_json );

use constant {
  TWILIO_BASE_URL => 'https://api.twilio.com/2010-04-01/',
  STATUS_FILE     => '/tmp/ember_status.json',
};

has [qw( twilio_from twilio_to twilio_sid twilio_token )];
has status_file => STATUS_FILE;

sub twilio_sms ($self) {
  croak 'Need: twilio_sid, twilio_token, twilio_from, twilio_to in config'
    unless $self->twilio_sid
    && $self->twilio_token
    && $self->twilio_from
    && $self->twilio_to;

  my $url_base = Mojo::URL->new(TWILIO_BASE_URL);

  my $ua      = Mojo::UserAgent->new;
  my $sms_url = $url_base->clone
    ->userinfo(join ':', $self->twilio_sid, $self->twilio_token)
    ->path(join '/', 'Accounts', $self->twilio_sid, 'Messages.json');

  my $result = $ua->post(
    $sms_url,
    form => {
      To       => $self->twilio_to,
      From     => $self->twilio_from,
      Body     => "\N{HOT BEVERAGE}",
    },
  )->result;

  return $result->code == 201;
}


# {
#   last_alert => '2020-03-21T00:00:00Z',
#   last_temp => 125,
#   last_time => '2020-03-21T00:00:01Z',
# }

sub status ($self) {
  my $input = qx{ \$HOME/bin/ember_rust };
  return unless
    my ($temp, $sp) = $input =~ /temp=(\d+),sp=(\d+)/;

  my $status_file = Mojo::File->new($self->status_file);
  my $status;
  $status = decode_json $status_file->slurp if -f $status_file;

  my $now_hour   = localtime->hour;
  my $now        = Mojo::Date->new;
  my $last_alert = Mojo::Date->new($status->{last_alert} // ($now->epoch - 3598));

  if (
    defined $temp && $temp < 100 && $status->{last_temp} >= 100
    && $now_hour < 14
    && $now->epoch - $last_alert->epoch > 60 * 60
  ) {
    $self->twilio_sms();
    $status->{last_alert} = $now->to_datetime;
  }

  $status->{last_alert} //= $last_alert->to_datetime;
  $status->{last_temp}    = $temp;
  $status->{last_time}    = $now->to_datetime;
  $status_file->spurt(encode_json $status);

  return "${temp}F/${sp}F";
}

sub click ($self, $button) {
  my $dispatch = {
    MOUSE_UP() => sub {
      system('$HOME/bin/ember_rust', '-u', '1');
    },
    MOUSE_DOWN() => sub {
      system('$HOME/bin/ember_rust', '-d', '1');
    },
  };

  return 1 unless defined $button && defined $dispatch->{$button};

  # Handle mouse button input
  $dispatch->{$button}->();

  return 1;
}

1;

