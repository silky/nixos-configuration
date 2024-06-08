{ config
, pkgs
, unstable
, cooklang-chef
, haskell-hacking-notebook
, ...
}:
let
  mkSym = file: config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/dev/nixos-configuration/users/${config.home.username}/${file}";

  hledgerFile = "${config.home.homeDirectory}/dev/life/accounts/hledger.journal";
  recipesDir = "${config.home.homeDirectory}/dev/life/recipes";
  unstablePkgs = import unstable {};

  # ---------------------------------------------------------------------------
  #
  # ~ Vim plugins
  #
  # ---------------------------------------------------------------------------
  vim-quickscope = pkgs.vimUtils.buildVimPlugin {
    name = "quick-scope";
    src = pkgs.fetchFromGitHub {
      owner = "unblevable";
      repo = "quick-scope";
      rev = "256d81e391a22eeb53791ff62ce65f870418fa71";
      sha256 = "sha256-TcA4jZIdnQd06V+JrXGiCMr0Yhm9gB6OMiTSdzMt/Qw=";
    };
  };

  vim-cooklang = pkgs.vimUtils.buildVimPlugin {
    name = "vim-cooklang";
    src = pkgs.fetchFromGitHub {
      owner = "silky";
      repo = "vim-cooklang";
      rev = "7f8c2190b5675ad4465e9719cd4b773c1db2ce6e";
      sha256 = "sha256-vWlk7G1V4DLC0G0f3GLEG3JsvAwJ637CPocmMmFxQek=";
    };
  };
  vim-autoread = pkgs.vimUtils.buildVimPlugin {
    name = "vim-autoread";
    src = pkgs.fetchFromGitHub {
      owner = "djoshea";
      repo = "vim-autoread";
      rev = "7e83d47a71fdafc271005fc39c89863204278c77";
      sha256 = "sha256-IGgJ/D2AGDtbO+RZk2zd+zO9ZtANsle4QSjsh+VOXpg=";
    };
  };
  nvim-hs-vim = pkgs.vimUtils.buildVimPlugin {
    name = "nvim-hs.vim";
    src = pkgs.fetchFromGitHub {
      owner = "neovimhaskell";
      repo = "nvim-hs.vim";
      rev = "d4a6b7278ae6a1fdc64e300c3ebc1e24719af342";
      sha256 = "sha256-umsuGGP5tOf92bzWEhqD2y6dN0FDBsmLx60f45xgmig=";
    };
  };
  noon-light-theme = pkgs.vimUtils.buildVimPlugin {
    name = "noon-light-theme";
    src = pkgs.fetchFromGitHub {
      owner = "silky";
      repo = "noon-light-vim";
      rev = "edbd5fc9477e5697747acc286f9af5bbbbec3d39";
      sha256 = "sha256-WtB9gcRVRL2isy18UIqZDvyxINHvRPp0FqYj3roXM9E=";
    };
  };
  vim-syntax-shakespeare = pkgs.vimUtils.buildVimPlugin {
    name = "vim-syntax-shakespeare";
    src = pkgs.fetchFromGitHub {
      owner = "pbrisbin";
      repo = "vim-syntax-shakespeare";
      rev = "2f4f61eae55b8f1319ce3a086baf9b5ab57743f3";
      sha256 = "sha256-sdCXJOvB+vJE0ir+qsT/u1cHNxrksMnqeQi4D/Vg6UA=";
    };
  };
  cabal-project-vim = pkgs.vimUtils.buildVimPlugin {
    name = "cabal-project-vim";
    src = pkgs.fetchFromGitHub {
      owner = "vmchale";
      repo = "cabal-project-vim";
      rev = "0d41e7e41b1948de84847d9731023407bf2aea04";
      sha256 = "sha256-j1igpjk1+j/1/y99ZaI3W5+VYNmQqsFp2qX4qzkpNpc=";
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
        google-chrome
        ungoogled-chromium

        # Hack so that gh browser doesn't say "Opening in new browser"
        (writers.writeDashBin "gh-browser" ''
          ${ungoogled-chromium}/bin/chromium-browser "$@" 1>/dev/null
        '')
      ];

      dev = [
        (agda.withPackages (p: [ p.standard-library p.cubical ]))
        csview
        delta
        difftastic
        dnsutils
        # docker
        docker-compose
        fd
        fx
        git-crypt
        google-cloud-sdk
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
        unixtools.xxd
        unstablePkgs.contour
        unstablePkgs.csvlens
        unstablePkgs.gh      # For gh-dash auth; `gh auth login`
        unstablePkgs.gh-dash # https://dlvhdr.github.io/gh-dash/
        unstablePkgs.ijq
        unstablePkgs.konsole
        vscode
        yq
        # zsh
      ];

      apps = [
        age
        cooklang-chef.packages.x86_64-linux.default
        docbook5
        gimp-with-plugins
        hunspell
        hunspellDicts.en-gb-ise
        inkscape
        lyx
        okular
        pandoc
        pass
        unstablePkgs.haskellPackages.hledger
        unstablePkgs.haskellPackages.hledger-ui
        unstablePkgs.haskellPackages.hledger-web
        unstablePkgs.vokoscreen-ng
        vlc
        xournalpp
      ];

      scripts = [
        mobile
        showBatteryState
        silver-desk
        work
      ];
    in
    web ++ dev ++ apps ++ scripts;


  # ---------------------------------------------------------------------------
  #
  # ~ Custom services
  #
  # ---------------------------------------------------------------------------
  # systemd.user.services.haskell-hacking-notebook = {
  #   Unit = {
  #     Description = "haskell-hacking-notebook";
  #     After = [ "graphical-session-pre.target" ];
  #     PartOf = [ "graphical-session.target" ];
  #   };
  #   Install = { WantedBy = [ "graphical-session.target" ]; };
  #   Service = {
  #     Restart = "on-failure";
  #     ExecStart = "${haskell-hacking-notebook.apps.x86_64-linux.default.program} --no-browser --port 5005 --IdentityProvider.token=abcd --notebook-dir /home/noon/tmp/haskell-hacking-notebooks";
  #     };
  # };

  # systemd.user.services.hledger = {
  #   Unit = {
  #     Description = "hledger-web";
  #     After = [ "graphical-session-pre.target" ];
  #     PartOf = [ "graphical-session.target" ];
  #   };
  #   Install = { WantedBy = [ "graphical-session.target" ]; };
  #   Service = {
  #     Restart = "on-failure";
  #     ExecStart =
  #       "${unstablePkgs.haskellPackages.hledger-web}/bin/hledger-web --serve -f ${hledgerFile}";
  #   };
  # };

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

  programs.firefox = {
    enable = true;
    profiles = {
      default = {
        settings = {
          "browser.urlbar.showSearchSuggestionsFirst" = false;
        };
        # TODO: Recover
        # extensions = with config.nur.repos.rycee.firefox-addons; [
        #   consent-o-matic # disabling cookie popups
        # ];
      };
    };
  };

  programs.emacs = {
    # No need for emacs at the moment.
    enable = false;
    package =
      let
        epkgs = epkgs: with epkgs;
          [
            agda2-mode
            all-the-icons
            atom-one-dark-theme
            company
            dashboard
            doom-modeline
          ];
      in
      (pkgs.emacsWithPackagesFromUsePackage
        {
          config = ./emacs/init.el;
          alwaysEnsure = true;
          package = pkgs.emacs-git;
        }
      );
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
    syntaxHighlighting = {
      enable = true;
      styles = {
        # See: <https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters/main.md>
        builtin = "none";
        command = "none";
        default = "none";
        alias = "none";
        function = "none";
        path = "none";
        # Don't highlight errors; it's okay.
        unknown-token = "none";
      };
    };
    defaultKeymap = "emacs";
    history = {
      size = 10000000;
      ignoreAllDups = true;
      ignoreDups = true;
      ignorePatterns = [ "rm *" "cd *" "pwd" "exit" "pkill *" ];
      ignoreSpace = true;
      share = true;
      extended = true;
    };

    initExtra = ''
      # History things
      HIST_STAMPS="yyyy-mm-dd"

      setopt INC_APPEND_HISTORY    # Write to the history file immediately, not when the shell exits.
      setopt HIST_SAVE_NO_DUPS     # Do not write a duplicate event to the history file.
      setopt HIST_VERIFY           # Do not execute immediately upon history expansion.
      setopt APPEND_HISTORY        # append to history file (Default)
      setopt HIST_NO_STORE         # Don't store history commands
      setopt HIST_REDUCE_BLANKS    # Remove superfluous blanks from each command line being added to the history.

      export FZF_DEFAULT_COMMAND='rg --hidden -g ""'

      # Control-arrows
      bindkey "^[[1;5C" forward-word
      bindkey "^[[1;5D" backward-word

      # Home/end
      bindkey "^[[H" beginning-of-line
      bindkey "^[[F" end-of-line

      bindkey "^?" backward-delete-char
      bindkey "^[[3~" delete-char

      autoload -z edit-command-line
      zle -N edit-command-line
      bindkey "^X^E" edit-command-line

      bindkey -e

      source ~/.profile

      export GPG_TTY="$(tty)"
      export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
      gpgconf --launch gpg-agent

      export PATH=~/.local/bin:$PATH
    '';

    plugins = with pkgs; [
      ({
        # https://github.com/agkozak/agkozak-zsh-prompt
        name = "agkozak-zsh-prompt";
        src = fetchFromGitHub {
          owner = "agkozak";
          repo = "agkozak-zsh-prompt";
          rev = "v3.11.1";
          sha256 = "sha256-TOfAWxw1uIV0hKV9o4EJjOlp+jmGWCONDex86ipegOY=";
        };
        file = "agkozak-zsh-prompt.plugin.zsh";
      })
    ];

    sessionVariables =
      let
        # Build up prompt
        executionTime = "%(9V.%F{247}%9v%f .)";
        exitStatus = "%(?..%F{\${AGKOZAK_COLORS_EXIT_STATUS}}(%?%)%f )";
        userAndHost = "%(!.%S.%F{cyan})%n%1v%(!.%s.%f)";
        envHint = "%(10V.%F{blue}[%10v]%f .)";
        path = "%F{green}%c%f";
        time = "%F{blue}%D{%I:%M %P}%f";
        gitStatus = "%(3V.%F{\${AGKOZAK_COLORS_BRANCH_STATUS}}%3v%f.)";
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
        AGKOZAK_PROMPT_CHAR = "φ φ# :";
        AGKOZAK_LEFT_PROMPT_ONLY = 1;
        AGKOZAK_MULTILINE = 0;
        AGKOZAK_CUSTOM_SYMBOLS = "⇣⇡ ⇣ ⇡ + x ! > ? S";

        # Day in the right, e.g.: "Tue Sep 27"
        AGKOZAK_CUSTOM_RPROMPT = "%F{blue}%D{%a %b %d}%f";
        AGKOZAK_CUSTOM_PROMPT = prompt;

        LS_COLORS = "di=36:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43";

        LANG = "en_US.UTF-8";
        LC_CTYPE = "en_US.UTF-8";
        LC_ALL = "en_US.UTF-8";

        # hledger
        # LEDGER_FILE = hledgerFile;

        # hunspell
        DICTIONARY = "en_GB";
        EDITOR = "nvim";

        # gh-dash
        GH_BROWSER = "gh-browser";
      };

    shellAliases = {
      # Nix
      rr = "direnv reload";
      n = "nix-shell";
      nix-shell-unstable = "nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
      nu = "nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";

      # Haskell
      b = "stack build --nix";
      bf = "stack build --nix --fast --file-watch";
      g = "stack ghci --nix";
      c = "cabal build";

      # hledger
      h = "hledger -s";

      # Git-releated
      ci = "git commit -m";
      co = "git checkout";
      gc = "git clone --recursive";
      gpr = "git pull --rebase";
      pp = "git push";
      st = "git status";
      gpo = "git push origin";

      # Fun
      shh = "ssh -q";

      # Shell
      ".." = "cd ..";
      "..." = "cd ../..";
      "cd.." = "cd ..";
      l = "ls -lah --color=auto";
      ll = "ls -lh --color=auto";
      ls = "ls --color=auto";
      md = "mkdir -p";

      # Misc
      dc = "docker compose";
      df = "df -h";
      f = "format";
      j = "jupyter notebook --no-browser --ip=localhost -y";
      m = "make";
      p = "python";
      rg = "rg -M 1000";
      # Open my main config by default
      d = "gh-dash --config ~/dev/life/gh-dash-configs/config.yml";

      # Text-editing
      v = "nvim";
      vim = "nvim";
      vv = "nvim -R";
      e = "emacs";

      # Don't ask (TZ)
      pc = "pre-commit";
      pca = "pre-commit run --all";
    };
  };


  # ---------------------------------------------------------------------------
  #
  # ~ Misc
  #
  # ---------------------------------------------------------------------------
  programs.gpg = {
    enable = true;
    package = unstablePkgs.gnupg;
  };

  services.dunst = {
    enable = true;

    iconTheme = {
      name = "BeautyLine";
      package = pkgs.beauty-line-icon-theme;
      size = "32x32";
    };

    settings = {
      global = {
        font = "Fira Code 12";
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

  services.gpg-agent = {
    enable = true;
  #   extraConfig = ''
  #     pinentry-program ${pkgs.pinentry.qt}/bin/pinentry
  #   '';
  };

  programs.direnv = {
    enable = true;
    package = unstablePkgs.direnv;
    config.global.hide_env_diff = true;
    nix-direnv.enable = true;
    nix-direnv.package = unstablePkgs.nix-direnv;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.neovim = {
    enable = true;
    extraConfig = builtins.readFile ./init.vim;
    plugins = with pkgs.vimPlugins; [
      {
        plugin = nvim-treesitter.withAllGrammars;
      }

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
      vim-quickscope
      vim-ledger
      vim-nix
      vim-ormolu
      vim-syntax-shakespeare
      vim-toml
      vim-textobj-user
      xterm-color-table
      nvim-hs-vim
      {
        # plugin packages in required Vim plugin dependencies
        plugin = pkgs.vimPlugins.cornelis;
        config = "let g:cornelis_use_global_binary = 1";
      }
    ];
    extraPackages = [ pkgs.cornelis ];
  };


  # ---------------------------------------------------------------------------
  #
  # ~ Files
  #
  # ---------------------------------------------------------------------------
  home.file = {
    # Note: Let's not let any app modify these files.
    ".config/konsolerc".source = ./konsolerc;
    ".stack/config.yaml".source = ./stack-config.yaml;

    # Agda
    ".agda/defaults".text = ''
      standard-library
    '';

    # Ones I prefer to modify in place
    ".gitconfig".source = mkSym "gitconfig";
    ".config/contour/contour.yml".source = mkSym "contour.yml";

    # These ones it's okay; it's easier to modify with the apps
    ".config/okularpartrc".source = mkSym "okularpartrc";
    ".local/share/konsole/Noons.colorscheme".source = mkSym "Noons.colorscheme";
    ".local/share/konsole/Profile 1.profile".source = mkSym "Profile 1.profile";
  };
}
