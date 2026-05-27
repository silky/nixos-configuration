{ config
, pkgs
, lib
, ...
}:
let
  mkSym = file: config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/dev/nixos-configuration/users/${config.home.username}/${file}";
in
{
  imports = [
    ../../modules/home-manager/zsh-common.nix
    ../../modules/home-manager/packages-common.nix
  ];

  home.stateVersion = "22.11";

  home.packages = with pkgs;
    let
      web = [
        ungoogled-chromium
      ];
      dev = [
        # docker
        docker-compose
        kdiff3
        google-cloud-sdk
        openssl
        kdePackages.konsole
        yq
      ];
      apps = [
        inkscape
        vlc
      ];
      scripts = [ ];
    in
    web ++ dev ++ apps ++ scripts;

  programs.firefox = {
    enable = true;
    configPath = ".mozilla/firefox";
  };

  # ---------------------------------------------------------------------------
  #
  # ~ Zsh — gala-specific overrides on top of zsh-common
  #
  # ---------------------------------------------------------------------------
  programs.zsh = import ./zsh.nix { inherit lib; };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    config.global.hide_env_diff = true;
    nix-direnv.enable = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  services.gpg-agent = {
    enable = true;
    #   extraConfig = ''
    #     pinentry-program ${pkgs.pinentry.qt}/bin/pinentry
    #   '';
  };

  programs.gpg = {
    enable = true;
  };

  home.file = {
    # Note: Let's not let any app modify these files.
    ".config/konsolerc".source = ./konsolerc;
    # These are okay.
    ".xmonad/xmonad.hs".source = mkSym "xmonad.hs";
    ".local/share/konsole/Galas.colorscheme".source = mkSym "./Galas.colorscheme";
    ".local/share/konsole/Profile 1.profile".source = mkSym "./Profile 1.profile";
  };
}
