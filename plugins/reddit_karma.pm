package reddit_karma;

use Mojo::Base 'i3Mojo::Plugin::Base', -signatures;
use i3Mojo::Util;
use Carp 'croak';

use Mojo::UserAgent;
use Mojo::JSON qw(decode_json encode_json);
use Mojo::File;
use Mojo::Util 'dumper';

use constant {
  TOKEN_FILE  => '/tmp/reddit_token.json',
  STATUS_FILE => '/tmp/reddit_status.json',
  USER_AGENT  => 'mojo_karma/0.1',
};


has app_id      => sub { croak 'app_id is required in config' };
has app_secret  => sub { croak 'app_secret is required in config' };
has username    => sub { croak 'username is required in config' };
has password    => sub { croak 'password is required in config' };
has user_agent  => 'mojo_karma/0.1';
has token_file  => '/tmp/reddit_token.json';
has status_file => '/tmp/reddit_status.json';
has token       => 1;


sub status ($self) {
  my $token_file = Mojo::File->new($self->token_file);
  my $token;
  $token = decode_json $token_file->slurp if -f $token_file;
  $self->token($self->token + 1);

  my $ua = Mojo::UserAgent->new;

  if (! $token->{expire_time} || time >= $token->{expire_time}) {
    undef $token;
    my $token_url = Mojo::URL->new('https://www.reddit.com/api/v1/access_token')
      ->userinfo(join ':', $self->app_id, $self->app_secret);
    # acquire new access token
    $token = $ua->post(
      $token_url => { 'User-Agent'  => USER_AGENT } => form => {
        grant_type => 'password',
        username   => $self->username,
        password   => $self->password,
      })->result->json;

    croak 'Token acquisition failed' unless $token;
    $token->{expire_time} = time + $token->{expires_in};

    $token_file->spurt(encode_json $token);
  }

  my $status_file = Mojo::File->new($self->status_file);
  my $previous;
  $previous = decode_json $status_file->slurp if -f $status_file;

  my $current = $ua->get(
    'https://oauth.reddit.com/user/' . $self->username . '/about',
    {
      'Authorization' => "bearer $token->{access_token}",
      'User-Agent'    => $self->user_agent,
    })->result
    ->json
    ->{data};

  $status_file->spurt(encode_json $current);
  $current //= $previous;

  my $text = '';
  my $color;

  if ($current->{inbox_count}) {
    $color = PRIORITY_CRITICAL;
  } elsif (
    $previous && (
      $current->{link_karma} != $previous->{link_karma}
      || $current->{comment_karma} != $previous->{comment_karma}
    )
  ) {
    $color = PRIORITY_IMPORTANT;
  }

  $text =
    "$current->{link_karma} · $current->{comment_karma}" .
    ($current->{inbox_count} ? "  ($current->{inbox_count})" : '');

  return $text, $color, { token => $self->token };
}

sub click ($self, $button) {
  system('xdg-open https://reddit.com/user/' . $self->username . ' >/dev/null') if
    $button == MOUSE_LEFT;
}

1;

