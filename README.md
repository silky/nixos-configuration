# noonos: nixos-configuration

wip

#### Todo

- [x] Vim plugins
- [x] Vim colourscheme
- [ ] Ssh key
- [ ] Terminal colour scheme
- [x] Aliases on root:
      - `rb` -> `nixos-rebuild switch -p`
      - ???

#### Longer todos/maybe todos

- [ ] Properly use home manager?


### Notes


To make Stack work (sad):

```
# ~/.stack/config.yaml
nix:
  packages: [ zlib.dev, zlib.out, pkgconfig ]
```
