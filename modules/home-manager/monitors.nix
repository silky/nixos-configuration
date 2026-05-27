{ pkgs, ... }:
# ---------------------------------------------------------------------------
#
# ~ Monitors — xrandr layouts shared across users
#
# ---------------------------------------------------------------------------
let
  work = pkgs.writeShellScriptBin "work" ''
    xrandr \
      --output HDMI-1 --mode 2560x1440 --pos 2560x0 --rotate right \
      --output DP-3 --primary --mode 2560x1440 --pos 0x766 \
      --output eDP-1 --off \
      --output DP-1 --off \
      --output DP-2 --off \
      --rotate normal --output DP-4 --off
     ~/.fehbg
  '';

  mobile = pkgs.writeShellScriptBin "mobile" ''
    xrandr \
      --output eDP-1 --primary --mode 2560x1600 --pos 0x0 --rotate normal \
      --output HDMI-1 --off \
      --output DP-1 --off \
      --output DP-2 --off \
      --output DP-3 --off \
      --output DP-4 --off
    ~/.fehbg
  '';

  climbing = pkgs.writeShellScriptBin "climbing" ''
      xrandr \
        --output DP-1 --primary --mode 3840x2160 --pos 0x0 --rotate normal \
        --output eDP-1 --off \
        --output HDMI-1 --off \
        --output DP-2 --off
    ~/.fehbg
  '';
in
{
  home.packages = [
    work
    mobile
    climbing
  ];
}
