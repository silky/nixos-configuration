{ config, pkgs, unstable, cooklang-chef, haskell-hacking-notebook, ... }:
let
  mkSym
    = file: config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/dev/nixos-configuration/users/${config.home.username}/${file}";

  hledgerFile  = "${config.home.homeDirectory}/dev/life/accounts/hledger.journal";
  recipesDir   = "${config.home.homeDirectory}/dev/life/recipes";
  unstablePkgs = import unstable {};

  # ---------------------------------------------------------------------------
  #
  # ~ Vim plugins
  #
  # ---------------------------------------------------------------------------
  vim-cooklang = pkgs.vimUtils.buildVimPlugin {
    name = "vim-cooklang";
    src = pkgs.fetchFromGitHub {
      owner  = "silky";
      repo   = "vim-cooklang";
      rev    = "7f8c2190b5675ad4465e9719cd4b773c1db2ce6e";
      sha256 = "sha256-vWlk7G1V4DLC0G0f3GLEG3JsvAwJ637CPocmMmFxQek=";
    };
  };
  vim-autoread = pkgs.vimUtils.buildVimPlugin {
    name = "vim-autoread";
    src = pkgs.fetchFromGitHub {
      owner  = "djoshea";
      repo   = "vim-autoread";
      rev    = "7e83d47a71fdafc271005fc39c89863204278c77";
      sha256 = "sha256-IGgJ/D2AGDtbO+RZk2zd+zO9ZtANsle4QSjsh+VOXpg=";
    };
  };
  noon-light-theme = pkgs.vimUtils.buildVimPlugin {
    name = "noon-light-theme";
    src = pkgs.fetchFromGitHub {
      owner  = "silky";
      repo   = "noon-light-vim";
      rev    = "690351b5208539f19cbdef738bdd4c9429f59557";
      sha256 = "sha256-22KUY2yGU0iVHPd9VLc5dg8gHECn7BV1wv3IRKfpvJM=";
    };
  };
  vim-syntax-shakespeare = pkgs.vimUtils.buildVimPlugin {
    name = "vim-syntax-shakespeare";
    src = pkgs.fetchFromGitHub {
      owner  = "pbrisbin";
      repo   = "vim-syntax-shakespeare";
      rev    = "2f4f61eae55b8f1319ce3a086baf9b5ab57743f3";
      sha256 = "sha256-sdCXJOvB+vJE0ir+qsT/u1cHNxrksMnqeQi4D/Vg6UA=";
    };
  };
  cabal-project-vim = pkgs.vimUtils.buildVimPlugin {
    name = "cabal-project-vim";
    src = pkgs.fetchFromGitHub {
      owner  = "vmchale";
      repo   = "cabal-project-vim";
      rev    = "0d41e7e41b1948de84847d9731023407bf2aea04";
      sha256 = "sha256-j1igpjk1+j/1/y99ZaI3W5+VYNmQqsFp2qX4qzkpNpc=";
    };
  };
  customNvim = pkgs.neovim.override {
    configure = {
      customRC = "source " + ./init.vim; # Note: Hack.
      packages.neovimPlugins = with pkgs.vimPlugins; { start = [
        cabal-project-vim
        dhall-vim
        editorconfig-vim
        elm-vim
        fzf-vim
        fzfWrapper
        haskell-vim
        noon-light-theme
        purescript-vim
        supertab
        typescript-vim
        unicode-vim
        vim-autoread
        vim-commentary
        vim-cooklang
        vim-easy-align
        vim-easymotion
        vim-ledger
        vim-nix
        vim-ormolu
        vim-syntax-shakespeare
        vim-toml
        vim-vue
        xterm-color-table
      ];};
    };
  };

  showBatteryState = pkgs.writeShellScriptBin "show-battery-state" ''
    mins=$(acpi | jc --acpi | jq '.[].charge_remaining_minutes')
    hrs=$(acpi | jc --acpi | jq '.[].charge_remaining_hours')
    pct=$(acpi | jc --acpi | jq '.[].charge_percent')
    ${pkgs.libnotify}/bin/notify-send "Battery" "Remaining: $hrs hr $mins m ($pct%)."
  '';

  # Hacky monitor things
  work = pkgs.writeShellScriptBin "work" ''
   xrandr \
      --output DP-1   --off \
      --output DP-2   --primary --mode 2560x1440 --pos 0x619 --rotate normal \
      --output HDMI-1 --mode 2560x1440 --pos 2560x0 --rotate left \
      --output eDP-1  --off
    ~/.fehbg
  '';
  silver-desk = pkgs.writeShellScriptBin "silver-desk" ''
   xrandr \
      --output DP-1   --mode 2560x1440 --pos 2560x0 --rotate right \
      --output DP-2   --primary --mode 2560x1440 --pos 0x560 --rotate normal \
      --output HDMI-1 --off \
      --output eDP-1  --off
    ~/.fehbg
  '';
  mobile = pkgs.writeShellScriptBin "mobile" ''
    xrandr \
      --output DP-1   --off \
      --output DP-2   --off \
      --output HDMI-1 --off \
      --output eDP-1  --primary --mode 2560x1400 --pos 0x0 --rotate normal
    ~/.fehbg
  '';
in
{
  home.stateVersion = "22.11";

  # ---------------------------------------------------------------------------
  #
  # ~ Programs
  #
  # ---------------------------------------------------------------------------
  home.packages = with pkgs;
    let
      web = [
        firefox
        google-chrome
        ungoogled-chromium
      ];

      dev = [
        csview
        customNvim
        delta
        difftastic
        docker
        docker-compose
        fx
        git-crypt
        html-tidy
        httpie
        jc
        jd-diff-patch
        jo
        jq
        kdiff3
        lychee
        moreutils
        nix-output-monitor
        nix-tree
        openssl
        python310
        python310Packages.keyring
        stack
        unstablePkgs.contour
        unstablePkgs.konsole
        vscode
        zsh
      ];

      sys = [
        acpi
        alsa-utils
        arandr
        brightnessctl
        dmenu
        feh
        ffmpeg_6-full
        flameshot
        gnome.eog
        gnome.gedit
        gnome.nautilus
        gnome.seahorse
        libnotify
        nethogs
        qmk
        xorg.xmodmap
      ];

      apps = [
        gimp-with-plugins
        imagemagick
        inkscape
        obsidian
        okular
        pandoc
        pass
        # Latest hledger
        unstablePkgs.haskellPackages.hledger-web
        unstablePkgs.haskellPackages.hledger
        # Broken.
        unstablePkgs.haskellPackages.hledger-ui
        vlc
        unstablePkgs.vokoscreen-ng
        xclip
        xournalpp
        texlive.combined.scheme-full
        # TODO: Use an argument instead of hard-coding the system.
        cooklang-chef.packages.x86_64-linux.default
      ];

      scripts = [
        mobile
        showBatteryState
        silver-desk
        work
      ];
    in
      web ++ dev ++ sys ++ apps ++ scripts;


  # ---------------------------------------------------------------------------
  #
  # ~ Custom services
  #
  # ---------------------------------------------------------------------------
  systemd.user.services.haskell-hacking-notebook = {
    Unit = {
      Description = "haskell-hacking-notebook";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Install = { WantedBy = [ "graphical-session.target" ]; };
    Service = {
      Restart = "on-failure";
      ExecStart = "${haskell-hacking-notebook.apps.x86_64-linux.default.program} --no-browser --port 5005 --IdentityProvider.token=abcd --notebook-dir /home/noon/tmp/haskell-hacking-notebooks";
      };
  };

  systemd.user.services.hledger = {
    Unit = {
      Description = "hledger-web";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Install = { WantedBy = [ "graphical-session.target" ]; };
    Service = {
      Restart = "on-failure";
      ExecStart =
        "${unstablePkgs.haskellPackages.hledger-web}/bin/hledger-web --serve -f ${hledgerFile}";
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
        "${cooklang-chef.packages.x86_64-linux.default}/bin/chef --path ${recipesDir} serve --port 5001";
      };
  };


  # ---------------------------------------------------------------------------
  #
  # ~ Zsh
  #
  # ---------------------------------------------------------------------------
  programs.zsh = {
    enable = true;
    autocd = true;
    enableCompletion = true;

    initExtra = ''
      # Control-arrows
      bindkey "^[[1;5C" forward-word
      bindkey "^[[1;5D" backward-word

      # Home/end
      bindkey "^[[H" beginning-of-line
      bindkey "^[[F" end-of-line

      bindkey "^?" backward-delete-char
      bindkey "^[[3~" delete-char

      bindkey -e

      source ~/.profile

      export GPG_TTY="$(tty)"
      export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
      gpgconf --launch gpg-agent

      export PATH=~/.local/bin:$PATH
    '';

    plugins = with pkgs; [
      {
        # https://github.com/agkozak/agkozak-zsh-prompt
        name = "agkozak-zsh-prompt";
        src = fetchFromGitHub {
          owner  = "agkozak";
          repo   = "agkozak-zsh-prompt";
          rev    = "v3.11.1";
          sha256 = "sha256-TOfAWxw1uIV0hKV9o4EJjOlp+jmGWCONDex86ipegOY=";
        };
        file = "agkozak-zsh-prompt.plugin.zsh";
      }
    ];

    sessionVariables =
      let
        # Build up prompt
        executionTime = "%(9V.%F{247}%9v%f .)";
        exitStatus    = "%(?..%F{\${AGKOZAK_COLORS_EXIT_STATUS}}(%?%)%f )";
        userAndHost   = "%(!.%S.%F{cyan})%n%1v%(!.%s.%f)";
        envHint       = "%(10V.%F{blue}[%10v]%f .)";
        path          = "%F{green}%c%f";
        time          = "%F{blue}%D{%I:%M %P}%f";
        gitStatus     = "%(3V.%F{\${AGKOZAK_COLORS_BRANCH_STATUS}}%3v%f.)";
        prompt = executionTime
                + exitStatus
                + time + " "
                + userAndHost + " φ "
                + envHint
                + path
                + gitStatus
                + " "
                ;
      in
    {
      AGKOZAK_PROMPT_CHAR      = "φ φ# :";
      AGKOZAK_LEFT_PROMPT_ONLY = 1;
      AGKOZAK_MULTILINE        = 0;
      AGKOZAK_CUSTOM_SYMBOLS   = "⇣⇡ ⇣ ⇡ + x ! > ? S";

      # Day in the right, e.g.: "Tue Sep 27"
      AGKOZAK_CUSTOM_RPROMPT  = "%F{blue}%D{%a %b %d}%f";
      AGKOZAK_CUSTOM_PROMPT   = prompt;

      LS_COLORS = "di=36:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43";

      LANG     = "en_US.UTF-8";
      LC_CTYPE = "en_US.UTF-8";
      LC_ALL   = "en_US.UTF-8";

      # hledger
      LEDGER_FILE = hledgerFile;

      # TODO: Work out how to reinstate so that it doesn't kill off emacs
      # bindings in the shell.
      # EDITOR   = "nvim";
    };

    shellAliases = {
      # Nix
      rr = "direnv reload";
      n                  = "nix-shell";
      nix-shell-unstable = "nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
      nu                 = "nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";

      # Haskell
      b  = "stack build --nix";
      bf = "stack build --nix --fast --file-watch";
      g  = "stack ghci --nix";
      c  = "cabal build";

      # hledger
      h = "hledger -s";

      # Git-releated
      ci  = "git commit -m";
      co  = "git checkout";
      gc  = "git clone --recursive";
      gpr = "git pull --rebase";
      pp  = "git push";
      st  = "git status";

      # Fun
      shh = "ssh -q";

      # Shell
      ".."   = "cd ..";
      "..."  = "cd ../..";
      "cd.." = "cd ..";
      l      = "ls -lah --color=auto";
      ll     = "ls -lh --color=auto";
      ls     = "ls --color=auto";
      md     = "mkdir -p";

      # Misc
      dc  = "docker compose";
      df  = "df -h";
      f   = "format";
      j   = "jupyter notebook --no-browser --ip=localhost -y";
      m   = "make";
      p   = "python";
      rg  = "rg -M 1000";
      v   = "nvim";
      vim = "nvim";
      vv  = "nvim -R";
    };
  };


  # ---------------------------------------------------------------------------
  #
  # ~ Misc
  #
  # ---------------------------------------------------------------------------
  programs.gpg = {
    enable  = true;
    package = unstablePkgs.gnupg;
  };

  services.dunst = {
    enable = true;

    iconTheme = {
      name    = "BeautyLine";
      package = pkgs.beauty-line-icon-theme;
      size    = "32x32";
    };

    settings = {
      global = {
        font        = "Fira Code 12";
        format      = "%s — %b";
        frame_width = "0";
        width       = "(0, 500)";
      };
      urgency_low = {
        background = "#e6e6fa";
        foreground = "#111111";
        timeout    = 3;
      };
      urgency_normal = {
        background = "#e6e6fa";
        foreground = "#111111";
        timeout    = 3;
      };
      urgency_critical = {
        background = "#ffe4e1";
        foreground = "#111111";
        timeout    = 4;
      };
    };
  };

  services.gpg-agent = {
    enable = true;
    extraConfig = ''
      pinentry-program ${pkgs.pinentry.qt}/bin/pinentry
    '';
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };


  # ---------------------------------------------------------------------------
  #
  # ~ Files
  #
  # ---------------------------------------------------------------------------
  home.file = {
    # Note: Let's not let any app modify these files.
    ".config/konsolerc".source = ./konsolerc;
    ".gitconfig".source = ./gitconfig;
    ".stack/config.yaml".source = ./stack-config.yaml;

    ".config/contour/contour.yml".source = mkSym "contour.yml";

    # These ones it's okay; it's easier to modify with Konsole then manually.
    ".local/share/konsole/Noons.colorscheme".source = mkSym "Noons.colorscheme";
    ".local/share/konsole/Profile 1.profile".source = mkSym "Profile 1.profile";
  };
}
