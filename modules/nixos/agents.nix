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
_:
{
  # Disable this for now.
  # environment.systemPackages = [ bounded-claude ];

  # The domain-allowlisting egress proxy the jail talks to. Filtering
  # happens on the CONNECT hostname, before any DNS resolution, so
  # denied domains never even resolve.
  # services.tinyproxy = {
  #   enable = true;
  #   settings = {
  #     Listen = "127.0.0.1";
  #     Port = proxyPort;
  #     Allow = "127.0.0.1";
  #     Timeout = 600;
  #     FilterDefaultDeny = true;
  #     FilterType = "fnmatch";
  #     Filter = toString (pkgs.writeText "claude-jail-allowed-domains"
  #       (lib.concatMapStrings (d: d + "\n") allowedDomains));
  #     ConnectPort = 443;
  #   };
  # };

  # # tinyproxy can only listen on TCP, so bridge it to the unix socket
  # # that gets bound into the jail.
  # systemd.services.claude-jail-proxy = {
  #   description = "unix socket into the claude jail's egress proxy";
  #   wantedBy = [ "multi-user.target" ];
  #   requires = [ "tinyproxy.service" ];
  #   after = [ "tinyproxy.service" ];
  #   serviceConfig = {
  #     DynamicUser = true;
  #     RuntimeDirectory = "claude-jail";
  #     ExecStart = "${pkgs.socat}/bin/socat UNIX-LISTEN:${proxySocket},fork,unlink-early,mode=666 TCP:127.0.0.1:${toString proxyPort}";
  #     Restart = "on-failure";
  #   };
  # };
}
