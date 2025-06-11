# i3mojo
An i3bar-compatible status command using the Perl Mojo framework
![image](https://user-images.githubusercontent.com/4522014/216459671-8f90062b-10dc-4f38-967d-8bf39026a707.png)

This script is intended to be a direct replacement for the `i3status` command.

Requirements:
- Perl (at least 5.22, I think?)
- Perl modules:
  - Mojolicious
  - Carp
  - YAML
  - Possibly more... TODO

Usage:
- Clone this repo: `git clone https://github.com/rage311/i3mojo` and make note of the directory it's in
- Change the i3 config to use this as the status command
  - In the i3 config file (`$HOME/.config/i3/config` by default) replace any existing `status_command ...` lines in the `bar { ... }` section with:
  `status_command perl /WHEREVER/YOU/PUT/IT/i3mojo/i3mojo.pl`
- Tweak the `i3mojo/config.yml` file to your heart's content to add/configure plugins, change status colors, etc.
