{ pkgs, ... }:
{
  # ---------------------------------------------------------------------------
  #
  # ~ Packages — shared across all users
  #
  # User-specific packages live in each user's home.nix and are merged on
  # top of this list by the home-manager module system.
  #
  # ---------------------------------------------------------------------------
  home.packages = with pkgs; [
    csvlens # CSV file viewer
    gcc
    gh # For gh-dash auth; `gh auth login`
    moreutils
    python314
    vscode
  ];
}
