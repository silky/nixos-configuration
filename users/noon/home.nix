{ config
, pkgs
, cooklang-chef
, lib
, ...
}:
let
  mkSym = file: config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/dev/nixos-configuration/users/${config.home.username}/${file}";
  recipesDir = "${config.home.homeDirectory}/dev/life/recipes";

  showBatteryState = pkgs.writeShellScriptBin "show-battery-state" ''
    mins=$(acpi | jc --acpi | jq '.[].charge_remaining_minutes')
    hrs=$(acpi | jc --acpi | jq '.[].charge_remaining_hours')
    pct=$(acpi | jc --acpi | jq '.[].charge_percent')
    ${pkgs.libnotify}/bin/notify-send "Battery" "Remaining: $hrs hr $mins m ($pct%)."
  '';

  # Hacky monitor things
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
      --output eDP-1 --off \
      --output HDMI-1 --off \
      --output DP-1 --off \
      --output DP-2 --off \
      --output DP-3 --mode 3840x2160 --pos 0x0 --rotate normal \
      --output DP-4 --off
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
        # Hack so that gh browser doesn't say "Opening in new browser"
        (writers.writeDashBin "gh-browser" ''
          chromium-browser "$@" 1>/dev/null
        '')
      ];

      dev = [
        (agda.withPackages (p: with p; [ standard-library cubical ]))
        dnsutils
        html-tidy # HTML formatter/tidier
        moreutils
        gron # Greppable JSON https://github.com/tomnomnom/gron
        xh # http request thingy https://github.com/ducaale/xh
        duc # disk usage
        ncdu # disk usage
        yazi # file browser
        gcc
        feedback # https://github.com/NorfairKing/feedback#readme
        python3
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
        # haskellPackages.fast-tags # For haskell-tools-nvim
        # haskellPackages.haskell-debug-adapter # For haskell-tools-nvim
        csvlens # CSV file viewer
        gh # For gh-dash auth; `gh auth login`
        gh-dash # GitHub dashboard https://dlvhdr.github.io/gh-dash/
        vscode # Sometimes useful
        websocat # Websocket chatting
        pciutils # Device debugging
        qemu # Emulation
        # j # J programming language
        frink # Calculator
        picat # Logic programming
        wasmtime # wasm runtime
      ];

      apps = [
        cooklang-chef.packages.x86_64-linux.default
        # discord-ptb
        docbook5
        haskellPackages.hledger
        haskellPackages.hledger-ui
        haskellPackages.hledger-web
        lorien # Whiteboardy thing
        pass
        steam-run # Running dynamically-linked executables
        xmobar
      ];

      scripts = [
        mobile
        showBatteryState
        work
        climbing
      ];
    in
    web ++ dev ++ apps ++ scripts;

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
        "${cooklang-chef.packages.x86_64-linux.default}/bin/chef --path ${recipesDir} serve --port 6006";
    };
  };

  programs.firefox = {
    enable = true;
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

  # programs.fish = {
  #   enable = true;
  # };

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
        global-alias = "none";
        suffix-alias = "none";
        function = "none";
        path = "none";
        autodirectory = "none";
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

    initContent = ''
      # History things
      HIST_STAMPS="yyyy-mm-dd"

      setopt INC_APPEND_HISTORY    # Write to the history file immediately, not when the shell exits.
      setopt HIST_SAVE_NO_DUPS     # Do not write a duplicate event to the history file.
      setopt HIST_VERIFY           # Do not execute immediately upon history expansion.
      setopt APPEND_HISTORY        # append to history file (Default)
      setopt HIST_NO_STORE         # Don't store history commands
      setopt HIST_REDUCE_BLANKS    # Remove superfluous blanks from each command line being added to the history.

      export FZF_DEFAULT_COMMAND='rg -M 1000 --.'

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

      export PATH=~/.local/bin:$PATH

      # https://lobste.rs/s/ahmi0i/quick_bits_realise_nix_symlinks
      function hijack() {
          local item
          for item; do
              if [[ ! -L "$item" ]]; then
                  continue
              fi

              local bak="$(dirname "$item")/.$(basename "$item").hijack.bak"
              local tmp="''${bak%.bak}.tmp"

              cp --no-dereference --remove-destination "$item" "$bak" || return $?

              rm -rf "$tmp" || return $?
              cp -r "$(readlink --canonicalize "$item")" "$tmp" || return $?
              chmod -R u+w "$tmp" || return $?

              rm "$item" || return $?
              mv "$tmp" "$item" || return $?
          done

          $EDITOR -- "$@"
          local ret=$?

          for item; do
              local bak="$(dirname "$item")/.$(basename "$item").hijack.bak"

              if [[ ! -e "$bak" ]]; then
                  continue
              fi

              mv "$bak" "$item" || return $?
          done

          return $ret
      }
    '';

    plugins = with pkgs; [
      {
        # https://github.com/agkozak/agkozak-zsh-prompt
        name = "agkozak-zsh-prompt";
        src = fetchFromGitHub {
          owner = "agkozak";
          repo = "agkozak-zsh-prompt";
          rev = "v3.11.3";
          sha256 = "sha256-TOfAWxw1uIV0hKV9o4EJjOlp+jmGWCONDex86ipegOY=";
        };
        file = "agkozak-zsh-prompt.plugin.zsh";
      }
    ];

    sessionVariables =
      let
        # Build up prompt
        executionTime = "%(9V.%F{247}%9v%f .)";
        exitStatus = "%(?..%F{\${AGKOZAK_COLORS_EXIT_STATUS}}(%?%)%f )";
        # userAndHost = "%(!.%S.%F{cyan})%n%1v%(!.%s.%f)";
        envHint = "%(10V.%F{blue}[%10v]%f .)";
        path = "%F{196}%c%f";
        time = "%F{blue}%D{%I:%M %P}%f";
        gitStatus = "%(3V.%F{\${AGKOZAK_COLORS_BRANCH_STATUS}}%3v%f.)";
        prompt = executionTime
          + exitStatus
          + time
          # + userAndHost
          + " φ "
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
        AGKOZAK_CUSTOM_RPROMPT = "%F{247}%D{%a %b %d}%f";
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
      bb = "nom build";

      fb = "feedback";

      # Haskell
      g = "ghci";
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
      df = "duf -only local -output mountpoint,size,used,usage,avail";
      f = "format";
      m = "make";
      p = "python";
      rg = "rg -M 1000 --.";
      # Open my main config by default
      d = "gh-dash --config ~/dev/life/gh-dash-configs/config.yml";
      # For glow, always use the pager
      glow = "glow -p";
      lg = "lazygit";
      wormhole = "wormhole-rs";

      # Text-editing
      v = "nvim";
      vim = "nvim";
      # w = vim in pairing mode (vv)
      w  = "nvim -c 'source ~/dev/nixos-configuration/users/noon/pairing.vim'";
      vv = "nvim -c 'source ~/dev/nixos-configuration/users/noon/pairing.vim'";
    };
  };


  # ---------------------------------------------------------------------------
  #
  # ~ Misc
  #
  # ---------------------------------------------------------------------------

  # Disabled presently due to home-manager zed config bug.
  # programs.zed-editor = {
  #   enable = true;
    # extensions = [
    #   "html"
    #   "haskell"
    #   "nix"
    # ];
    # userSettings = {
    #   buffer_font_family = iMWritingMono Nerd Font";
    #   them = {
    #     mode = "system";
    #     light = "Catppuccin Latte";
    #   };
    # };
  # };

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

  # services.gpg-agent = {
  #   enable = true;
  #   enableSshSupport = true;
  #   pinentryPackage = pkgs.pinentry-qt;
  # };

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
    ".hspec".source = mkSym "hspec";
    ".gitignore".source = mkSym "gitignore";
    ".gitconfig".source = mkSym "gitconfig";
    ".editorconfig".source = mkSym "editorconfig";
    ".config/alacritty/alacritty.toml".source = mkSym "alacritty.toml";

    # haskell-tools lsp madness
    # ".config/nvim/after/ftplugin/haskell.lua".source = mkSym "haskell.lua";

    # These ones it's okay; it's easier to modify with the apps
    ".rgignore".source = mkSym "rgignore";
    ".config/okularpartrc".source = mkSym "okularpartrc";
  };
}
