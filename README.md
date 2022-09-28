# noonos: nixos-configuration

### Usage

Starting from nothing:

1. Install some kind of nixos,
1. Edit the `/etc/nixos/configuration.nix` to have `git`,
1. Rebuild ( `nixos-rebuild switch` )
1. Clone `silky/dotfiles` and this repo, `silky/nixos-configuration`,
1. `cd` into this repo and run
  ```
  nixos-rebuild switch --flake '.' --impure
  ```
1. Happiness!
1. You can now delete all `.nix` files in `/etc/nixos` if you wish.
1. And otherwise hopefully enjoy your life.


### Annoyances

- Have to delete the pre-defined `~/.config/konsolerc`.


### References/inspiration

- <https://gitlab.com/rprospero/dotfiles>
- <https://github.com/mitchellh/nixos-config>
- <https://github.com/kalbasit/shabka/blob/master/modules/home/software/zsh/>
- <https://github.com/Yumasi/nixos-home/blob/master/zsh.nix>
- <https://github.com/haskie-lambda/nixconfig/blob/a8fe974c6c151169c1d686cbb04fc2cdf2a2c05d/nixos/v2/pkgConfigs/zsh.nix>
- <https://github.com/toonn/nix-config>


### Todo

- [ ] fix up colours in zsh theme
- [ ] make home-manager "actually" work;
  - [ ] i.e. ensure there's a home-manager command
  - [ ] ensure it can be re-run without being root
  - [ ] etc
- [ ] copy and paste from vim
- [ ] configure ls
- [ ] configure bat
- [x] fzf in vim
- [x] git config
- [x] `~/.stack/config.yaml`
- [x] noon-light zsh theme
- [x] konsole configuration
  - [x] symlink to editable files instead of readonly ones.
- [x] nixos-hardware 9th-gen
