{ config
, pkgs
, lib
, cooklang-chef
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
    ../../modules/home-manager/scripts.nix
    ../../modules/home-manager/monitors.nix
  ];

  home.stateVersion = "22.11";

  # ---------------------------------------------------------------------------
  #
  # ~ Programs
  #
  # ---------------------------------------------------------------------------
  home.packages = with pkgs;
    let
      web = [
        google-chrome
        # Hack so that gh browser doesn't say "Opening in new browser"
        (writers.writeDashBin "gh-browser" ''
          chromium-browser "$@" 1>/dev/null
        '')
      ];

      dev = [
        (agda.withPackages (p: with p; [ standard-library cubical ]))
        dnsutils
        gron # Greppable JSON https://github.com/tomnomnom/gron
        duc # disk usage
        ncdu # disk usage
        yazi # file browser
        # Random haskell hacking
        (ghc.withPackages (
          p: with p;
          [
            QuickCheck
            aeson
            containers
            lens
            mtl
            text
            vector
          ]
        ))
        gh-dash # GitHub dashboard https://dlvhdr.github.io/gh-dash/
        websocat # Websocket chatting
        pciutils # Device debugging
        qemu # Emulation
        picat # Logic programming
        wasmtime # wasm runtime
      ];

      apps = [
        lorien # Whiteboardy thing
        steam-run # Running dynamically-linked executables
        xmobar
      ];
    in
    web ++ dev ++ apps;

  programs.chromium = {
    package = pkgs.ungoogled-chromium;
    enable = true;
    # TODO: These aren't installed.
    extensions = [
      { id = "mdjildafknihdffpkfmmpnpoiajfjnjd"; } # Consent-O-Matic
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # uBlock Origin
    ];
  };

  # ---------------------------------------------------------------------------
  #
  # ~ Custom services
  #
  # ---------------------------------------------------------------------------
  systemd.user.services."battery-low" = {
    Unit = {
      Enable = true;
      Description = "Notify user if battery is below 10%";
      PartOf = [ "graphical-session.target" ];
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = pkgs.writeShellScript "battery-low-notification"
        ''
          if (( 10 >= $(${pkgs.lib.getExe pkgs.acpi} -b \
            | head -n 1 \
            | ${pkgs.lib.getExe pkgs.ripgrep} -o "\d+%" \
            | ${pkgs.lib.getExe pkgs.ripgrep} -o "\d+")));
          then \
            ${pkgs.lib.getExe pkgs.pkgs.libnotify} \
            --urgency=critical "low battery" \
            "$(${pkgs.lib.getExe pkgs.acpi} -b \
            | head -n 1 \
            | ${pkgs.lib.getExe pkgs.ripgrep} -o "\d+%")";
          else echo; fi;
        '';
    };
  };

  systemd.user.timers."battery-low" = {
    timerConfig = {
      wantedBy = [ "timers.target" ];
      # Every Minute
      OnCalendar = "*-*-* *:*:00";
      Unit = "battery-low.service";
    };
  };

  systemd.user.services.cooklang-chef = {
    Unit = {
      Description = "cooklang-chef";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Install = { WantedBy = [ "graphical-session.target" ]; };
    Service = {
      Restart = "on-failure";
      ExecStart =
        let recipesDir = "/home/noon/dev/life/recipes";
        in "${cooklang-chef.packages.x86_64-linux.default}/bin/chef --path ${recipesDir} serve --port 6006";
    };
  };

  programs.firefox = {
    enable = true;
    configPath = ".mozilla/firefox";
    profiles = {
      default = {
        settings = {
          "browser.urlbar.showSearchSuggestionsFirst" = false;
        };
        # TODO: This don't seem to work
        # extensions = with config.nur.repos.rycee.firefox-addons; [
        #   consent-o-matic # disabling cookie popups
        # ];
      };
    };
  };

  programs.yt-dlp = {
    enable = true;
    package = pkgs.yt-dlp;
    settings = {
      audio-format = "best";
      audio-quality = 0;
      embed-chapters = true;
      embed-metadata = true;
      embed-subs = true;
      embed-thumbnail = true;
      remux-video = "aac>m4a/mov>mp4/mkv";
      sponsorblock-mark = "sponsor";
      sub-langs = "all";
    };
  };

  # ---------------------------------------------------------------------------
  #
  # ~ Zsh — noon-specific overrides on top of zsh-common
  #
  # ---------------------------------------------------------------------------
  programs.zsh = import ./zsh.nix { inherit lib; };


  # ---------------------------------------------------------------------------
  #
  # ~ Misc
  #
  # ---------------------------------------------------------------------------

  services.dunst = {
    enable = true;

    iconTheme = {
      name = "BeautyLine";
      package = pkgs.beauty-line-icon-theme;
      size = "32x32";
    };

    settings = {
      global = {
        font = "iMWritingMono Nerd Font 12";
        format = "%s — %b";
        frame_width = "0";
        width = "(0, 500)";
      };
      urgency_low = {
        background = "#e6e6fa";
        foreground = "#111111";
        timeout = 3;
      };
      urgency_normal = {
        background = "#e6e6fa";
        foreground = "#111111";
        timeout = 3;
      };
      urgency_critical = {
        background = "#ffe4e1";
        foreground = "#111111";
        timeout = 4;
      };
    };
  };

  services.gnome-keyring.enable = true;

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

  programs.neovim = import ./vim.nix { inherit pkgs; };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    # Replace cd with z and add cdi to access zi
    options = [
      "--cmd cd"
    ];
  };


  # ---------------------------------------------------------------------------
  #
  # ~ Files
  #
  # ---------------------------------------------------------------------------
  home.file = {
    # Note: Let's not let any app modify these files.
    ".stack/config.yaml".source = ./stack-config.yaml;

    # Agda
    ".agda/defaults".text = ''
      standard-library
    '';

    # Ones I prefer to modify in place
    ".xmonad/xmonad.hs".source = mkSym "xmonad.hs";
    ".gitignore".source = mkSym "gitignore";
    ".gitconfig".source = mkSym "gitconfig";
    ".editorconfig".source = mkSym "editorconfig";
    ".config/alacritty/alacritty.toml".source = mkSym "alacritty.toml";
    ".config/ghostty/config".source = mkSym "ghost-config";

    # haskell-tools lsp madness
    # ".config/nvim/after/ftplugin/haskell.lua".source = mkSym "haskell.lua";

    # These ones it's okay; it's easier to modify with the apps
    ".rgignore".source = mkSym "rgignore";
    ".config/okularpartrc".source = mkSym "okularpartrc";
  };
}
