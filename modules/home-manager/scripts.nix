{ pkgs, ... }:
# ---------------------------------------------------------------------------
#
# ~ Scripts — small shell utilities shared across users
#
# Anything defined here is added to home.packages for every user that
# imports this module.
#
# ---------------------------------------------------------------------------
let
  showBatteryState = pkgs.writeShellScriptBin "show-battery-state" ''
    mins=$(acpi | jc --acpi | jq '.[].charge_remaining_minutes')
    hrs=$(acpi | jc --acpi | jq '.[].charge_remaining_hours')
    pct=$(acpi | jc --acpi | jq '.[].charge_percent')
    ${pkgs.libnotify}/bin/notify-send "Battery" "Remaining: $hrs hr $mins m ($pct%)."
  '';
in
{
  home.packages = [
    showBatteryState
  ];
}
