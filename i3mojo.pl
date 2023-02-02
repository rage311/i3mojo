#!/usr/bin/env perl

use 5.034;

use Mojo::Base -base, -signatures;
use Mojo::IOLoop;
use Mojo::Collection;
use Mojo::JSON qw(encode_json decode_json);
use Mojo::Util qw(dumper trim);
use Mojo::Log;

use Carp 'croak';
use YAML 'LoadFile';
use FindBin '$RealBin';

use lib "$RealBin/plugins";
use lib "$RealBin/lib";


use constant I3BAR_CONFIG => {
  version      => 1,
  click_events => \1, # boolean true
};

use constant CONFIG_FILE => $ARGV[0] // $RealBin . '/config.yml';

has config => sub { state $config = LoadFile CONFIG_FILE };

has instances => sub ($self) {
  croak 'modules not found in config' unless
    state $instances = Mojo::Collection->new($self->config->{modules}->@*);
};

has log => sub ($self) {
  state $log = Mojo::Log->new(
    path  => $self->config->{log}{path}  // "/tmp/i3mojo.log",
    level => $self->config->{log}{level} // 'info'
  );
};

has loop => sub { state $loop = Mojo::IOLoop->new };
has rpc  => sub ($self) { croak 'rpc not loaded' };

sub load_modules ($self) {
  $self->instances->each(sub ($instance, $index) {
    my $module = $instance->{module};
    $self->log->info("Loading $module");
    eval { require "$module.pm"; 1 };
    $self->log->error("Unable to load: $module. $@") and return if $@;
    $instance->{instance} = eval { $module->new($instance->{config} || {}) };
  });
}

sub make_i3_message ($self) {
  return $self->instances->map(sub {
      return () unless $_->{new_status};
      return {
        full_text => ($_->{icon} ? "$_->{icon} " : '') . $_->{new_status},
        name      => $_->{module},
        instance  => "$_->{instance}",
        color     => $self->config->{colors}[$_->{priority} // 0],
      }
    })
    ->compact
    ->to_array;
}

sub write_output ($self) {
  say encode_json($self->make_i3_message), ',';
}

sub instance_changed ($self, $instance) {
  return
    !$instance->{last_status}
    || $instance->{new_status} ne $instance->{last_status}
    || !defined $instance->{last_priority}
    || ( defined $instance->{new_priority}
        && $instance->{new_priority} != $instance->{last_priority}
       );
}

sub run_instance_long ($self, $instance) {
  my $sub = $self->loop->subprocess;
  $self->log->debug("run_instance_long: ", dumper $instance->{instance});

  $sub->on(progress => sub ($sub, @data) {
    return $self->log->warn("run_instance_long no data: " . dumper \@data)
      unless ($instance->{new_status}, $instance->{priority}) = @data;

    $self->log->info("run_instance_long: $instance->{instance}, $instance->{new_status}");
    $self->write_output if $self->instance_changed($instance);
  });

  $sub->run(
    sub ($sub) { $instance->{instance}->listen($sub) },
    sub ($sub, $err, @results) {
      $self->log->error(
        'subprocess log error: ',
        dumper $sub,
        dumper $err,
        dumper \@results
      ) if $err;
    });
}

sub run_instance ($self, $instance, $new_status = undef) {
  $self->loop->subprocess(
    sub ($sub) {
      return $new_status ? @$new_status : $instance->{instance}->status;
    },
    sub ($sub, $err, @results) {
      $self->log->error("Subprocess ERROR: $err") and return if $err;
      $self->log->debug("No result $instance->{module}: $instance->{instance}")
        and return unless
        ($instance->{new_status}, $instance->{priority}) = @results;

      $self->write_output if $self->instance_changed($instance);

      $instance->{last_status}   = $instance->{new_status};
      $instance->{last_priority} = $instance->{priority};
    });
}

sub match_instance ($self, $id) {
  $self->log->debug("match_instance: '$id'");
  return $self->instances->first(sub {
    "$_->{instance}" eq "$id";
  });
}

sub listen_input ($self) {
  my $stream = Mojo::IOLoop::Stream->new(\*STDIN)->timeout(0);

  $stream->on(read => sub ($stream, $bytes) {
    $bytes = trim $bytes;
    return unless length $bytes > 0 && $bytes =~ /(\{.+\})/;

    my $click_event = eval { decode_json $1 };

    $self->log->debug("Click:\n\t" . dumper $click_event);
    $self->log->error('Unable to match instance id') and return unless
      my $match = $self->match_instance($click_event->{instance});

    $match->{instance}->click($click_event->{button});
    $self->run_instance($match) if $match->{interval} ne 'listen';
  });

  $stream->on(error => sub ($stream, $err) {
    $self->log->error("Error: $err");
  });

  $stream->on(close => sub {
    $self->log->warn('STDIN stream closed');
    $stream->start;
  });

  $stream->start;

  $self->loop->stream($stream);
}


my $self = __PACKAGE__->new();
$self->log->info('i3mojo starting...');
$self->log->info('Log level: ' . $self->log->level);
$self->load_modules;

# don't buffer output
autoflush STDOUT 1;

# print header
say encode_json I3BAR_CONFIG;

# start i3 infinite array output
say '[';

$self->instances->each(sub ($instance, $) {
  if ($instance->{interval} eq 'listen') {
    # launch only, don't set recurring execution -- is there a need for interval + listen?
    $self->run_instance_long($instance);
  } else {
    $self->run_instance($instance);
    $self->loop->recurring(
      $instance->{interval} => sub { $self->run_instance($instance) }
    );
  }
});

$self->listen_input;
$self->loop->start;

