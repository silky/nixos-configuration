{ pkgs, ... }:
{
  # ---------------------------------------------------------------------------
  #
  # ~ Zsh — shared across all users
  #
  # User-specific configuration (prompt, FZF defaults, editor, per-user
  # aliases, extra init snippets) lives in each user's home.nix and is
  # merged on top of this module by the home-manager module system.
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

    sessionVariables = {
      AGKOZAK_LEFT_PROMPT_ONLY = 1;
      AGKOZAK_MULTILINE = 0;
      AGKOZAK_CUSTOM_SYMBOLS = "⇣⇡ ⇣ ⇡ + x ! > ? S";

      LS_COLORS = "di=36:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43";

      LANG = "en_US.UTF-8";
      LC_CTYPE = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";

      # hunspell
      DICTIONARY = "en_GB";
    };

    shellAliases = {
      # Shell
      ".." = "cd ..";
      "..." = "cd ../..";
      "cd.." = "cd ..";
      l = "ls -lah --color=auto";
      ll = "ls -lh --color=auto";
      ls = "ls --color=auto";
      md = "mkdir -p";

      # Misc
      df = "duf -only local -output mountpoint,size,used,usage,avail";
      rg = "rg -M 1000 --.";
      dc = "docker compose";
      m = "make";
      p = "python";
    };
  };
}
