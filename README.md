# noonos: nixos-configuration

### (Approximate) Usage

(Something like the below works; You'll of course need to do some busywork
 with your auto-generated hardware nix file.)

Starting from nothing:

1. Install some kind of nixos,
1. Edit the `/etc/nixos/configuration.nix` to have `git`,
1. Rebuild ( `nixos-rebuild switch` )
1. Clone this repo, `silky/nixos-configuration`,
1. `cd` into this repo and run
  ```
  nixos-rebuild switch --flake '.' --impure
  ```
1. Happiness!
1. You can now delete all `.nix` files in `/etc/nixos` if you wish.
1. And otherwise hopefully enjoy your life.


### References/inspiration

- <https://github.com/mitchellh/nixos-config>
- <https://gitlab.com/rprospero/dotfiles>
- <https://github.com/kalbasit/shabka/blob/master/modules/home/software/zsh/>
- <https://github.com/Yumasi/nixos-home/blob/master/zsh.nix>
- <https://github.com/haskie-lambda/nixconfig/blob/a8fe974c6c151169c1d686cbb04fc2cdf2a2c05d/nixos/v2/pkgConfigs/zsh.nix>
- <https://github.com/toonn/nix-config>


### Todo

- [ ] Set up some timers: <https://nixos.wiki/wiki/Systemd/Timers>
- [ ] Do something nice with `xrandr | jc -xrandr` in order to work out:
  - How to turn off all monitors aside from the laptop
- [ ] Describe how to interact with the autogenerated hardware thing.

More recent todo:

- [ ] Resolve Todo items
- [ ] Don't use `./noon/common-configuration.nix` for all users
- [ ] Common-ish zsh config for people

### Trivia

- Run `nix-collect-garbage -d` _as root_, in order to delete everything.
