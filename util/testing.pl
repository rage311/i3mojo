#!/usr/bin/env perl

use v5.38.2;

use FindBin '$RealBin';
use lib "$RealBin/plugins";
use lib "$RealBin/lib";


use constant PRIORITIES => [qw/
  PRIORITY_NORMAL
  PRIORITY_IMPORTANT
  PRIORITY_URGENT
  PRIORITY_CRITICAL
/];

die "Module name (without extension) must be supplied as argument."
  unless
  my $module = shift @ARGV;

eval { require "$module.pm"; 1 };

die "Unable to create instance: $!"
  unless
  my $instance = eval {
    $module->new()#{ path => '/tmp/mypipe' })
  };

while (1) {
  say for $instance->status;
  sleep 1;
}
