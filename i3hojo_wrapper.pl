# perl i3hojo_wrapper.pl linux_battery '{"sys_path":"/sys/class/power_supply/BAT1"}'

use 5.038;

use Mojo::Base -base, -signatures;
use Mojo::JSON 'decode_json';
use Mojo::Util 'dumper';

use FindBin '$RealBin';
use lib "$RealBin/plugins";
use lib "$RealBin/lib";

use constant PRIORITY_NORMAL    => 0;
use constant PRIORITY_IMPORTANT => 1;
use constant PRIORITY_URGENT    => 2;
use constant PRIORITY_CRITICAL  => 3;

my $plug_name   = $ARGV[0];
my $plug_config = $ARGV[1];
# say "plug: $plug_name";
# say "plug_config: $plug_config";
my $config = eval { decode_json $plug_config };
# say dumper $config;

eval { require "$plug_name.pm"; 1 };
warn ("Unable to load: $plug_name. $@")
  and return
  if $@;

my $plug = eval { $plug_name->new($config // {}) };
my ($text, $urgency) = $plug->status;
$urgency //= PRIORITY_NORMAL;

say "${urgency}:::${text}";
