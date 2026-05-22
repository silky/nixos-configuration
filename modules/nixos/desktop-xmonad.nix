{ config, lib, ... }:
{
  options.myConfig.primaryUser = lib.mkOption {
    type = lib.types.str;
    default = "noon";
    description = "User automatically logged in to the X session.";
  };

  config = {
    # Screen locking
    programs.slock.enable = true;

    services = {
      displayManager = {
        autoLogin = {
          user = config.myConfig.primaryUser;
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
          config = ./desktop-xmonad/xmonad.hs;
        };
      };
    };
  };
}
