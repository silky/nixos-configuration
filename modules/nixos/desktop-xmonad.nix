{ config, pkgs, ... }:
{
  # Screen locking
  programs.slock.enable = true;

  # Flameshot registers a D-Bus single-instance service (org.flameshot.Flameshot)
  # on first use and stays resident; later invocations just message that same
  # process. A suspend/resume with a monitor-topology change (lid-close while
  # docked) can leave that long-lived process wedged, so `flameshot gui` quietly
  # does nothing. Kill it after resume so the next capture spawns a fresh one.
  systemd.services.flameshot-restart-after-resume = {
    description = "Kill flameshot after resume so it restarts cleanly";
    after = [ "suspend.target" ];
    wantedBy = [ "suspend.target" ];
    serviceConfig.Type = "oneshot";
    script = "${pkgs.procps}/bin/pkill -x flameshot || true";
  };

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
