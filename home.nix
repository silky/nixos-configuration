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
      bindkey "^[[1;5C" forward-word
      bindkey "^[[1;5D" backward-word
      bindkey '\e[OH' beginning-of-line
      bindkey '\e[OF' end-of-line
      bindkey '^[[H' beginning-of-line
      bindkey '^[[F' end-of-line
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
        userAndHost   = "%(!.%S.%F{\${AGKOZAK_COLORS_USER_HOST}})%n%1v%(!.%s.%f) ";
        envHint       = "%(10V.%F{\${AGKOZAK_COLORS_VIRTUALENV}}[%10v]%f .)";
        path          = "%F{\${AGKOZAK_COLORS_PATH}}%2v%f";
        time          = "%D{%I:%M %P}";
        jobStatus     = "%(1j. %F{\${AGKOZAK_COLORS_BG_STRING}}%jj%f.)";
        gitStatus     = "%(3V.%F{\${AGKOZAK_COLORS_BRANCH_STATUS}}%3v%f.)";
        prompt = executionTime
                + exitStatus
                + time + " "
                + userAndHost + " φ "
                + envHint
                + path
                + jobStatus
                + gitStatus
                + " "
                ;

        # prompt = path;
      in
    {
      AGKOZAK_PROMPT_CHAR      = "φ φ# :";
      AGKOZAK_LEFT_PROMPT_ONLY = 1;
      AGKOZAK_MULTILINE        = 0;
      AGKOZAK_CUSTOM_SYMBOLS   = "⇣⇡ ⇣ ⇡ + x ! > ? S";

      # Day in the right, e.g.: "Tue Sep 27"
      AGKOZAK_CUSTOM_RPROMPT  = "%D{%a %b %d}";
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
