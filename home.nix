# Home-Manager configuration
{ config, pkgs, ... }:
let
  mkSym = config.lib.file.mkOutOfStoreSymlink;

in {
  programs.zsh = {
    enable = true;

    # Todo:
    #
    # - [ ] Delete key actually deletes.
    # - [x] Home/End keys.
    #
    initExtra = ''
      # Control-arrows
      bindkey "^[[1;5C" forward-word
      bindkey "^[[1;5D" backward-word

      # Home/end
      bindkey "^[[H" beginning-of-line
      bindkey "^[[F" end-of-line

      bindkey "^?" backward-delete-char
      bindkey "^[[3~" delete-char
    '';

    plugins = with pkgs; [
      {
        # https://github.com/agkozak/agkozak-zsh-prompt
        name = "agkozak-zsh-prompt";
        src = fetchFromGitHub {
          owner = "agkozak";
          repo = "agkozak-zsh-prompt";
          rev = "v3.7.0";
          sha256 = "1iz4l8777i52gfynzpf6yybrmics8g4i3f1xs3rqsr40bb89igrs";
        };
        file = "agkozak-zsh-prompt.plugin.zsh";
      }
    ];

    sessionVariables =
      let
        # Build up prompt
        executionTime = "%(9V.%F{\${AGKOZAK_COLORS_CMD_EXEC_TIME}}%b%9v%b%f .)";
        exitStatus    = "%(?..%B%F{\${AGKOZAK_COLORS_EXIT_STATUS}}(%?%)%f%b )";
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
    };

    shellAliases = {
      # Nix
      n = "nix-shell";

      # Haskell
      b = "stack build";
      bf = "stack build --fast";
      g = "stack ghci";

      # Git-releated
      ci = "git commit -m";
      co = "git checkout";
      gc = "git clone --recursive";
      gpr = "git pull --rebase";
      pp = "git push";
      st = "git status";

      # Fun
      shh = "ssh -q";

      # Shell
      ".." = "cd ..";
      l    = "ls -lah";
      ll   = "ls -lh";
      # ls   = "ls";

      # Misc
      dc  = "docker-compose";
      p   = "python";
      rg  = "rg -M 1000";
      v   = "nvim";
      vim = "nvim";
    };
  };

  programs.direnv = {
    enable = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  home.file = {
    ".gitconfig".source = mkSym "${config.home.homeDirectory}/dev/nixos-configuration/home/gitconfig";
    ".config/konsolerc".source = mkSym "${config.home.homeDirectory}/dev/nixos-configuration/home/konsolerc";
    ".config/stack.yaml".source = mkSym "${config.home.homeDirectory}/dev/nixos-configuration/home/stack-config.yaml";

    ".local/share/konsole/Noons.colorscheme".source = mkSym "${config.home.homeDirectory}/dev/dotfiles/konsole/Noons.colorscheme";
    ".local/share/konsole/Profile 1.profile".source = mkSym "${config.home.homeDirectory}/dev/dotfiles/konsole/Profile 1.profile";
  };
}
