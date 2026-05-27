# gala-specific zsh config. Merged on top of modules/home-manager/zsh-common.nix
# via the home-manager module system.
{ lib, ... }:
{
  initContent = lib.mkAfter ''
    export FZF_DEFAULT_COMMAND='rg --hidden -g ""'

    export GPG_TTY="$(tty)"
    export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
    gpgconf --launch gpg-agent
  '';

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

      # Day in the right, e.g.: "Tue Sep 27"
      AGKOZAK_CUSTOM_RPROMPT = "%F{blue}%D{%a %b %d}%f";
      AGKOZAK_CUSTOM_PROMPT = prompt;

      EDITOR = "vscode";
    };

  shellAliases = {
  };
}
