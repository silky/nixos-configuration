# Jailed coding agents, via <https://git.sr.ht/~alexdavid/jail.nix>.
#
# `claude` on $PATH is the jailed one: it runs inside a bubblewrap
# sandbox that can only see the cwd, the nix store (read-only), and the
# specific dotfiles bound below. Because escapes are bounded by bwrap,
# it's safe to skip the per-tool permission prompts inside the jail.
# The unjailed escape hatch is `unsafe-claude`.
#
# Network is deny-by-default: the jail has no network namespace. Its
# only route out is a unix socket bound into the jail, which bridges
# to a tinyproxy instance on the host that only permits CONNECTs to
# `allowedDomains`. Inside the jail, a socat re-exposes that socket as
# an HTTP proxy on the jail's private loopback, and HTTP(S)_PROXY
# points the tools at it. No resolv.conf is bound: DNS happens on the
# host, in tinyproxy, only for allowed names.
{ pkgs, lib, jail-nix, ... }:
let
  jail = jail-nix.lib.init pkgs;

  proxyPort = 8888; # tinyproxy, on the host's loopback
  proxySocket = "/run/claude-jail/proxy.sock";
  jailProxyPort = 3128; # forwarded proxy, on the jail's loopback
  jailProxyUrl = "http://127.0.0.1:${toString jailProxyPort}";


  # fnmatch patterns, one per line in tinyproxy's filter file. Note
  # that `github.com` does not match `api.github.com`; wildcards only
  # via `*`.
  allowedDomains = [
    # Claude Code
    "api.anthropic.com"
    "statsig.anthropic.com"
    "claude.ai" # OAuth login flow
    "console.anthropic.com"
  ];

  # Tools the jailed agent should find on $PATH inside the sandbox.
  agentPackages = with pkgs; [
    bash
    coreutils
    curl
    direnv
    fd
    findutils
    gitMinimal
    gnugrep
    gnused
    inetutils
    jq
    ripgrep
    tree
    # LIVEHACKING
    # python3
  ];

  dangerousClaude = pkgs.writeShellScriptBin "bounded-claude" ''
    exec ${pkgs.claude-code}/bin/claude --dangerously-skip-permissions "$@"
  '';

  # LIVEHACKING
  # dangerousClaude = pkgs.writeShellScriptBin "bounded-claude" ''
  #   exec ${pkgs.bash}/bin/bash
  # '';

  bounded-claude = jail "bounded-claude" dangerousClaude (
    with jail.combinators;
    [
      # Network
      # ===========================================================================
      # Deliberately no `network` combinator: without it the network
      # namespace is unshared, so the jail's only way out is the
      # allowlisting proxy socket below. (bwrap brings up the private
      # loopback by itself.)
      (readwrite proxySocket)
      (runtime-deep-ro-bind "/etc/ssl") # CA certs; `network` normally binds these
      time-zone
      (set-env "HTTP_PROXY" jailProxyUrl)
      (set-env "HTTPS_PROXY" jailProxyUrl)
      (set-env "http_proxy" jailProxyUrl)
      (set-env "https_proxy" jailProxyUrl)
      (set-env "NO_PROXY" "localhost,127.0.0.1")
      (set-env "no_proxy" "localhost,127.0.0.1")
      (wrap-entry (entry: ''
        ${pkgs.socat}/bin/socat \
          "TCP-LISTEN:${toString jailProxyPort},bind=127.0.0.1,fork,reuseaddr" \
          "UNIX-CONNECT:${proxySocket}" 2>/dev/null &
        for _ in {1..50}; do
          if (echo > /dev/tcp/127.0.0.1/${toString jailProxyPort}) 2>/dev/null; then
            break
          fi
          sleep 0.1
        done
        ${entry}
      ''))
      # LIVEHACKING
      # network


      # Directories
      # ===========================================================================
      mount-cwd
      (try-fwd-env "CLAUDE_CONFIG_DIR")
      (try-readwrite (noescape "~/.claude"))
      (try-readwrite (noescape "~/.claude.json"))
      (try-readonly (noescape "~/.gitignore"))
      # LIVEHACKING
      (try-readonly (noescape "~/tmp/talk/bb"))


      # Packages
      # ===========================================================================
      (add-pkg-deps agentPackages)
    ]
  );
in
{
  environment.systemPackages = [ bounded-claude ];

  # The domain-allowlisting egress proxy the jail talks to. Filtering
  # happens on the CONNECT hostname, before any DNS resolution, so
  # denied domains never even resolve.
  services.tinyproxy = {
    enable = true;
    settings = {
      Listen = "127.0.0.1";
      Port = proxyPort;
      Allow = "127.0.0.1";
      Timeout = 600;
      FilterDefaultDeny = true;
      FilterType = "fnmatch";
      Filter = toString (pkgs.writeText "claude-jail-allowed-domains"
        (lib.concatMapStrings (d: d + "\n") allowedDomains));
      ConnectPort = 443;
    };
  };

  # tinyproxy can only listen on TCP, so bridge it to the unix socket
  # that gets bound into the jail.
  systemd.services.claude-jail-proxy = {
    description = "unix socket into the claude jail's egress proxy";
    wantedBy = [ "multi-user.target" ];
    requires = [ "tinyproxy.service" ];
    after = [ "tinyproxy.service" ];
    serviceConfig = {
      DynamicUser = true;
      RuntimeDirectory = "claude-jail";
      ExecStart = "${pkgs.socat}/bin/socat UNIX-LISTEN:${proxySocket},fork,unlink-early,mode=666 TCP:127.0.0.1:${toString proxyPort}";
      Restart = "on-failure";
    };
  };
}
