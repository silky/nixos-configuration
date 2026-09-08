# noon-specific zsh config. Merged on top of modules/home-manager/zsh-common.nix
# via the home-manager module system.
{ lib, ... }:
{
  syntaxHighlighting.styles = {
    global-alias = "none";
    suffix-alias = "none";
    autodirectory = "none";
  };

  initContent = lib.mkAfter ''
    export FZF_DEFAULT_COMMAND='rg -M 1000 --.'

    # Completion for the `git wt` alias (see users/noon/gitconfig). Zsh's
    # native _git dispatches to `_git-<name>` functions before expanding
    # aliases, so defining this is enough to hook in.
    _git-wt() {
      local curcontext=$curcontext state line ret=1
      declare -A opt_args

      _arguments -C \
        ': :->command' \
        '*:: :->option-or-argument' && ret=0

      case $state in
        (command)
          local -a subcommands
          subcommands=(
            'add:add a worktree in wts/ for a new, local, or origin branch'
            'ls:list worktrees'
            'rm:remove a worktree'
            'path:print the path of a worktree'
            'prune:prune stale worktree information'
          )
          _describe -t commands 'git wt subcommand' subcommands && ret=0
          ;;
        (option-or-argument)
          case $line[1] in
            (add)
              _alternative \
                'branch-names::__git_branch_names' \
                'remote-branch-names-noprefix::__git_remote_branch_names_noprefix' && ret=0
              ;;
            (rm|remove|path)
              local base expl
              base="$(cd "$(git rev-parse --git-common-dir 2>/dev/null)/../.." 2>/dev/null && pwd)/wts"
              local -a wts
              wts=($base/*(N/:t))
              _wanted worktrees expl 'worktree' compadd -a wts && ret=0
              ;;
          esac
          ;;
      esac
      return ret
    }

    # Allow comments in interactive mode
    setopt INTERACTIVE_COMMENTS

    # rp <ripgrep args> -- ripgrep with normal grouped output, pick a match, open in $EDITOR.
    function rp() {
        if [[ $# -eq 0 ]]; then
            echo "usage: rp <ripgrep args>" >&2
            return 2
        fi

        local pick
        pick=$(command rg --color=always --heading -n "$@" \
            | awk 'function strip(s,   r) { r = s; gsub(/\033\[[0-9;]*m/, "", r); return r }
                   { p = strip($0)
                     if (p == "")        { print "\t"; next }
                     if (p ~ /^[0-9]+:/) { print f "\t" $0; next }
                     f = p; print f "\t" $0 }' \
            | fzf --ansi --no-sort --layout=reverse \
                  --delimiter=$'\t' --with-nth=2.. --nth=2.. \
                  --color='fg+:-1:regular,bg+:#ffe0ec,gutter:-1' \
                  --select-1 --exit-0)
        local rc=$?
        (( rc != 0 )) && return $rc
        [[ -z "$pick" ]] && return 130

        local file rest plain line
        file=''${pick%%$'\t'*}
        rest=''${pick#*$'\t'}
        plain=$(printf '%s' "$rest" | sed $'s/\033\\[[0-9;]*m//g')
        line=''${plain%%:*}
        if [[ -z "$file" || ! "$line" =~ ^[0-9]+$ ]]; then
            echo "rp: pick a match line, not a header or blank." >&2
            return 1
        fi

        "''${EDITOR:-nvim}" "+''${line}" -- "$file"
    }
  '';

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
        + " "
        + envHint
        + path
        + gitStatus
        + " "
      ;
    in
    {
      AGKOZAK_PROMPT_CHAR = " # :";

      # Day in the right, e.g.: "Tue Sep 27"
      AGKOZAK_CUSTOM_RPROMPT = "%F{247}%D{%a %b %d}%f";
      AGKOZAK_CUSTOM_PROMPT = prompt;

      EDITOR = "nvim";

      # gh-dash
      GH_BROWSER = "gh-browser";

      # Conflict with git diff at present
      # LESS = "-Ric -x4 --use-color -Dd+r$Du+b";
    };

  shellAliases = {
    # Nix
    rr = "direnv reload";
    nu = "nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
    n = "nix";

    # Git-related
    ci = "git commit -m";
    co = "git checkout";
    gc = "git clone --recursive";
    gpr = "git pull --rebase";
    pp = "git push";
    st = "git status";
    gpo = "git push origin";

    j = "just";
    # A convenient  alias for "just test" or "just t"
    jt = "just test";

    # Haskell
    g = "ghci";

    # Git
    d = "git diff";

    # Fun
    shh = "ssh -q";

    # Open my main config by default
    gd = "gh-dash --config ~/dev/life/gh-dash-configs/config.yml";
    wormhole = "wormhole-rs";

    # Text-editing
    v = "nvim";
    vim = "nvim";
    e = "emacsclient -t";

    pclaude = "CLAUDE_CONFIG_DIR=~/.personal-claude claude";
    cc = "claude";
  };
}
