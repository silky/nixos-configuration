{ pkgs, lib, ... }:
# ---------------------------------------------------------------------------
#
# ~ Monitors — xrandr layouts shared across users
#
# Each attribute below becomes a `<name>` binary on PATH, reached from xmonad
# through the Alt-Shift-D ("(D)isplay") submap. `displayLayouts` in
# users/noon/xmonad.hs has to list the same names.
#
# ---------------------------------------------------------------------------
let
  # A mode change blanks the root pixmap, so every layout repaints the
  # wallpaper afterwards -- that is what the trailing ~/.fehbg is for.
  layout = name: body: pkgs.writeShellScriptBin name ''
    ${lib.removeSuffix "\n" body}
    ~/.fehbg
  '';
in
{
  home.packages = lib.mapAttrsToList layout {
    mobile = ''
      xrandr \
        --output eDP-1 --primary --mode 2560x1600 --pos 0x0 --rotate normal \
        --output HDMI-1 --off \
        --output DP-1 --off \
        --output DP-2 --off \
        --output DP-3 --off \
        --output DP-4 --off
    '';

    climbing = ''
      xrandr \
        --output DP-1 --primary --mode 3840x2160 --pos 0x0 --rotate normal \
        --output eDP-1 --off \
        --output HDMI-1 --off \
        --output DP-2 --off
    '';

    climbing-dual = ''
      xrandr \
        --output eDP-1 --mode 2560x1600 --pos 0x560 --rotate normal \
        --output DP-1 --primary --mode 3840x2160 --pos 2560x0 --rotate normal \
        --output HDMI-1 --off \
        --output DP-2 --off
    '';

    summer-house = ''
      xrandr \
        --output DP-1 --primary --mode 2560x1440 --pos 0x0 --rotate normal \
        --output HDMI-1 --mode 2560x1440 --pos 2560x0 --rotate normal \
        --output eDP-1 --off \
        --output DP-2 --off
    '';
  };
}
