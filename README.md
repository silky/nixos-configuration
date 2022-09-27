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


### Annoyances

- Have to delete the pre-defined `~/.config/konsolerc`.


### References/inspiration

- <https://gitlab.com/rprospero/dotfiles>
- <https://github.com/mitchellh/nixos-config>
- <https://github.com/kalbasit/shabka/blob/master/modules/home/software/zsh/>
- <https://github.com/Yumasi/nixos-home/blob/master/zsh.nix>
- <https://github.com/haskie-lambda/nixconfig/blob/a8fe974c6c151169c1d686cbb04fc2cdf2a2c05d/nixos/v2/pkgConfigs/zsh.nix>


### Todo

- [ ] git config
- [ ] fix up colours in zsh theme
- [ ] other random stuff
- [x] noon-light zsh theme
- [x] konsole configuration
  - [x] symlink to editable files instead of readonly ones.
- [x] nixos-hardware 9th-gen
