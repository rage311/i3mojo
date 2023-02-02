package i3Mojo::JSONRPC;

##
## THIS IS VERY MUCH A WORK IN PROGRESS, NOT CURRENTLY USABLE
##

use Mojo::Base -base, -signatures;
#use Carp 'croak';
use Mojo::JSON qw(encode_json decode_json);
use Mojo::Util qw(trim dumper);
use Mojo::Log;

#has log  => sub { state Mojo::Log->new('json_rpc_log.txt') };
has log  => sub { state $log = Mojo::Log->new(path => '/tmp/i3mojo_jsonrpc.log') };
has port => 54321;
has 'parent';

sub rpc_methods ($self, $req) {
  {
    list => sub {
      return eval {
        encode_json
          $self->make_rpc_response($req->{id}, ${$self->parent}->make_i3_message)
      }
    },
    update => sub {
      $self->log->debug("Searching for '$req->{params}{module}'") if $req->{params}{module};
      $self->log->debug("Searching for '$req->{params}{instance}'") if $req->{params}{instance};
      my $instance = $req->{params}{instance}
        ? $self->match_instance($req->{params}{instance})
        : $self->match_module($req->{params}{module});
      $self->log->debug(dumper $instance);
      my $new_status = $req->{params}{new_status};
      $self->log->debug('new status: ' . "\n" . dumper $new_status) if $new_status;

      ${$self->parent}->run_instance($instance, $new_status);
      return encode_json '{}';
    },
    get_output => sub { encode_json '{}' },
  }
}


# only match a module name if it's unique
sub match_module ($self, $mod_name) {
  $self->log->debug("match_module $mod_name");
  return ${$self->parent}->instances->first(sub {
    $self->log->debug(dumper $_);
    $self->log->debug("$_->{module}" eq $mod_name);
    "$_->{module}" eq $mod_name
  });
}

sub match_instance ($self, $id) {
  $self->log->debug("match_instance $id");
  return ${$self->parent}->instances->first(sub {
    $self->log->debug(dumper $_);
    "$_->{instance}" eq $id
  });
}

# doesn't need to be self ?
sub make_rpc_response ($self, $id, $result = undef, $error = undef) {
  my $response = {
    jsonrpc => '2.0',
    id      => $id,
  };

  if ($result) {
    $response->{result} = $result;
  } elsif ($error) {
    $response->{error} = $error;
  }

  $self->log->warn("rpc response: ", dumper $response);

  return $response;
}

sub json_rpc ($self, $bytes) {
  # attempt to parse as json
  my $req = eval { decode_json trim $bytes };
  $self->log->error("Error decoding as JSON RPC message: $bytes") and return '{}'
    if $@;

  # minimum requirements
  $self->log->error('JSON RPC issues: ' . dumper $req) and return unless
    defined $req->{jsonrpc}
    && $req->{jsonrpc} == '2.0'
    && defined $req->{method};
    #&& defined $rpc_methods->{$req->{method}};

  $self->log->debug(dumper $req);

  my $rpc_methods = {
    list => sub {
      return eval {
        encode_json $self->make_rpc_response($req->{id}, $self->make_i3_message)
      }
    },
    update => sub {
      $self->log->debug("Searching for '$req->{params}{module}'") if $req->{params}{module};
      $self->log->debug("Searching for '$req->{params}{instance}'") if $req->{params}{instance};
      my $instance = $req->{params}{instance}
        ? $self->match_instance($req->{params}{instance})
        : $self->match_module($req->{params}{module});
      $self->log->debug(dumper $instance);
      my $new_status = $req->{params}{new_status};
      $self->log->debug('new status: ' . "\n" . dumper $new_status) if $new_status;

      $self->run_instance($instance, $new_status);
      return encode_json '{}';
    },
    get_output => sub { encode_json '{}' },
  };

  # list method
  #return eval { to_json $self->make_i3_message };
  #$self->log->warn("json_rpc method defined: ", defined $rpc_methods->{$req->{method}});
  $self->log->debug(dumper $self->rpc_methods($req));
  #$self->log->warn("json_rpc method defined: ", defined $self->rpc_methods($req)->{$req->{method}});
  #return $rpc_methods->{$req->{method}}->();
  return $self->rpc_methods($req)->{$req->{method}}->();
}

sub listen ($self) {#, $loop) {
  my $port = $self->port;
  $self->log->info("Listening for TCP messages on port $port...");

  ${$self->parent}->loop->server({ port => $port } => sub ($loop, $stream, $id) {
    $stream->on(read => sub ($stream, $bytes) {
      chomp($bytes);
      for my $msg (split /\n/, $bytes) {
        my $response = $self->json_rpc($msg);
        $stream->write($response . "\n");
      }
      #$stream->close_gracefully;
    });
  });
}

1;
