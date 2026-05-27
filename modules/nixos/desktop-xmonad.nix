{ config, ... }:
{
  # Screen locking
  programs.slock.enable = true;

  services = {
    displayManager = {
      autoLogin = {
        user = config.myConfig.defaultUser;
        enable = true;
      };
    };
  };

  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
      options = "caps:escape";
    };
    # https://mynixos.com/nixpkgs/option/services.xserver.xrandrHeads
    displayManager = {
      sessionCommands = ''
        # Set a background.
        ~/.fehbg || true

        # No screen saving.
        xset s off -dpms
      '';
    };
    windowManager = {
      xmonad = {
        enable = true;
        enableContribAndExtras = true;
        extraPackages = p: [ p.split ];
        # Per-user config: each user provides ~/.xmonad/xmonad.hs (symlinked
        # from users/<name>/xmonad.hs via home-manager). With `config` unset,
        # the system xmonad recompiles from $HOME/.xmonad at login.
      };
    };
  };
}
