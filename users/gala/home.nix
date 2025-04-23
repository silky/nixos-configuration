{ config
, pkgs
, ...
}:
let
  mkSym = file: config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/dev/nixos-configuration/users/${config.home.username}/${file}";
in
{
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
        moreutils
        openssl
        kdePackages.konsole
        vscode
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

    initContent = ''
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
      {
        # https://github.com/agkozak/agkozak-zsh-prompt
        name = "agkozak-zsh-prompt";
        src = fetchFromGitHub {
          owner = "agkozak";
          repo = "agkozak-zsh-prompt";
          rev = "v3.11.1";
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
        userAndHost = "%(!.%S.%F{cyan})%n%1v%(!.%s.%f)";
        envHint = "%(10V.%F{blue}[%10v]%f .)";
        path = "%F{green}%c%f";
        time = "%F{blue}%D{%I:%M %P}%f";
        gitStatus = "%(3V.%F{\${AGKOZAK_COLORS_BRANCH_STATUS}}%3v%f.)";
        prompt = executionTime
          + exitStatus
          + time + " "
          + userAndHost + " ○ "
          + envHint
          + path
          + gitStatus
          + " "
        ;
      in
      {
        AGKOZAK_PROMPT_CHAR = "○ ○# :";
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

        # hunspell
        DICTIONARY = "en_GB";
        EDITOR = "vscode";
      };

    shellAliases = {
      # Nix
      rr = "direnv reload";
      n = "nix-shell";
      nix-shell-unstable = "nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
      nu = "nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";

      # Git-releated
      ci = "git commit -m";
      co = "git checkout";
      gc = "git clone --recursive";
      gpr = "git pull --rebase";
      pp = "git push";
      st = "git status";
      gpo = "git push origin";

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
    };
  };

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
    ".local/share/konsole/Galas.colorscheme".source = mkSym "./Galas.colorscheme";
    ".local/share/konsole/Profile 1.profile".source = mkSym "./Profile 1.profile";
  };
}
