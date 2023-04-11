{ config, pkgs, unstable, ... }:
let
  mkSym
    = file: config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/dev/nixos-configuration/users/${config.home.username}/${file}";

  unstablePkgs = import unstable {};


  # ---------------------------------------------------------------------------
  #
  # ~ Vim plugins
  #
  # ---------------------------------------------------------------------------
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
      rev    = "5746f68d4a407ddbc3add2f60db758b9b178dcc4";
      sha256 = "sha256-OLDb/yMs6sUDSrt8fFa82pF6p9eeNi02N2PKrto/C6I=";
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
        vim-easy-align
        vim-easymotion
        vim-nix
        vim-ormolu
        vim-syntax-shakespeare
        vim-toml
        vim-vue
        xterm-color-table
      ];};
    };
  };
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
        customNvim
        docker
        docker-compose
        httpie
        jc
        jq
        nix-output-monitor
        pkg-config
        python310
        python310Packages.keyring
        stack
        unstablePkgs.konsole
        zsh
      ];

      sys = [
        acpi
        alsa-utils
        arandr
        dmenu
        feh
        flameshot
        gnome.gedit
        gnome.nautilus
        gnome.seahorse
        nethogs
      ];

      apps = [
        inkscape
        nomacs
        okular
        pandoc
        pass
        vlc
        xclip
      ];
    in
      web ++ dev ++ sys ++ apps;


  # ---------------------------------------------------------------------------
  #
  # ~ Zsh
  #
  # ---------------------------------------------------------------------------
  programs.zsh = {
    enable = true;

    initExtra = ''
      # Control-arrows
      bindkey "^[[1;5C" forward-word
      bindkey "^[[1;5D" backward-word

      # Home/end
      bindkey "^[[H" beginning-of-line
      bindkey "^[[F" end-of-line

      bindkey "^?" backward-delete-char
      bindkey "^[[3~" delete-char

      source ~/.profile

      export GPG_TTY="$(tty)"
      export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
      gpgconf --launch gpg-agent
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
      EDITOR   = "nvim";
    };

    shellAliases = {
      # Nix
      n  = "nix-shell";
      rr = "direnv reload";

      # Haskell
      b  = "stack build --nix";
      bf = "stack build --nix --fast --file-watch";
      g  = "stack ghci --nix";

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
      dc  = "docker-compose";
      df  = "df -h";
      m   = "make";
      p   = "python";
      rg  = "rg -M 1000";
      v   = "nvim";
      vim = "nvim";
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

    # These ones it's okay; it's easier to modify with Konsole then manually.
    ".local/share/konsole/Noons.colorscheme".source = mkSym "Noons.colorscheme";
    ".local/share/konsole/Profile 1.profile".source = mkSym "Profile 1.profile";
  };
}
