{ name, config, pkgs, unstable, ... }:
let
  unstablePkgs = import unstable { };
in
{

  # See: https://nixos.wiki/wiki/Fwupd
  #
  #   fwupmgr refresh
  #   fwupmgr get-updates
  #   fwupmgr update
  #
  services.fwupd.enable = true;


  programs.atop.enable = true;

  # ---------------------------------------------------------------------------
  #
  # ~ System Packages
  #
  # ---------------------------------------------------------------------------
  environment.pathsToLink = [
    "/share/bash-completion"
    "/share/zsh"
  ];

  environment.systemPackages = with pkgs;
    let
      sys = [
        acpi # For power information
        alsa-utils # Music control
        arandr # Graphical xrandr
        autoconf # ???
        automake # ???
        bashmount # Mount disks via TUI
        binutils # ???
        brightnessctl # Useful to change brightness
        btop # Cool usage thing
        cachix # Nix Caching
        curl # No explanation needed
        dmenu # Launcher; used in XMonad setup
        duf # Modern df
        fuse # ???
        git
        git-crypt
        git-lfs
        gmp # ??
        gnumake # ??
        htop # Process viewer
        libnotify # Notifications
        libtool # ???
        lsof # ???
        neovim # Standard one; not customised.
        ntfs3g # ???
        p7zip # Yet another archive format
        pavucontrol # Audio
        procs # Modern ps
        psmisc # ???
        qmk # ???
        systemctl-tui # tui for systemd glancing
        tree # Tree view of directory
        unzip
        wget
        xclip # Copy things to clipboard
        xorg.xev # See key codes
        xorg.xkill # Kill windows
        xorg.xmodmap # Key mappings
        xsel # Copy things to clipboard (used in init.vim)
        zip
      ];
      dev = [
        alacritty # Terminal
        csview # For viewing csv's
        delta # Delta git diff configuration
        difftastic # Modern diffing
        docker-compose
        fd # Nicer find
        fx # Json viewer

        (google-cloud-sdk.withExtraComponents
          (with google-cloud-sdk.components; [
            gke-gcloud-auth-plugin
            gsutil
            kubectl
          ])
        )
        certbot

        hexyl # Hex viewer
        httpie # Simpler curl
        hyperfine # Benchmarking
        ijq # Interactive JQ
        jc # Convert many outputs to json for further investigation
        jd-diff-patch # JSON diff
        jless # Interactive json exploring
        jo # Create JSON
        jq # JSON explorer
        # k9s # Kubernetes cluster management
        konsole # Terminal
        lychee # Markdown link checker
        nix-prefetch-git # Get nix hashes
        nix-tree # Browse nix dependency graphs
        nvd # Nix package version diff
        openssl # Sometimes useful
        ripgrep # File searcher
        sd # Modern find and replace
        yq # jq for yaml
      ];
      app = [
        age # Encryption tools
        asciicam # Terminal webcam
        asciinema # Terminal recorder
        asciinema-agg # Convert asciinema to .gif
        bandwhich # Bandwidth monitor
        baobab # Disk space analyser
        chafa # Terminal image viewer
        eog # Image viewer
        feh # Set background images
        ffmpeg_6-full # Video things
        gimp-with-plugins # For making memes
        glow # Terminal Markdown renderer
        hunspell # Spelling
        hunspellDicts.en-gb-ise # Spelling
        imagemagick # Essential image tools
        inkscape # Meme creation
        lyx # For writing WYSIWYG TeX
        meld # Visual diff tool
        nautilus # File browser
        nix-output-monitor # Nicer build info when nixing
        okular # PDF viewing
        optipng # Optimise pngs
        pandoc # Occasionally useful
        pkgs.gedit # When times get desperate
        rofimoji # Emoji picker
        texlive.combined.scheme-full # Full TeX environment
        unstablePkgs.flameshot # Take screenshots
        unstablePkgs.vokoscreen-ng # Screen recording for videos
        vlc # For videos
        xournalpp # PDF writing
      ];
    in
    sys ++ dev ++ app
  ;

  # ---------------------------------------------------------------------------
  #
  # ~ Nix
  #
  # ---------------------------------------------------------------------------
  #
  # Prevent /boot from filling up
  boot.loader.grub.configurationLimit = 5;
  nix = {
    gc = {
      automatic = true;
      randomizedDelaySec = "14m";
      options = "--delete-older-than 30d";
    };

    settings.trusted-users = [ "root" "noon" "gala" ];
    extraOptions = ''
      experimental-features = nix-command flakes recursive-nix ca-derivations
      log-lines = 300
      warn-dirty = false
    '';
  };

  nixpkgs.config = {
    # TODO: Somehow this isn't enough to allow unfree; I still seem to need
    # the environment variable.
    allowUnfree = true;
    allowUnfreePredicate = _pkg: true;
    permittedInsecurePackages = [
      "electron-25.9.0"
    ];
  };


  # ---------------------------------------------------------------------------
  #
  # ~ Window Manager
  #
  # ---------------------------------------------------------------------------
  services = {
    displayManager = {
      autoLogin = {
        user = "noon";
        enable = true;
      };
    };
  };

  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
      options = "caps:escape";
    };
    # https://mynixos.com/nixpkgs/option/services.xserver.xrandrHeads
    displayManager = {
      sessionCommands = ''
        # Set a background.
        ~/.fehbg || true

        # No screen saving.
        xset s off -dpms
      '';
    };
    windowManager = {
      xmonad = {
        enable = true;
        enableContribAndExtras = true;
        extraPackages = p: [ p.split ];
        config = ./xmonad.hs;
      };
    };
  };


  # ---------------------------------------------------------------------------
  #
  # ~ Networking
  #
  # ---------------------------------------------------------------------------
  networking = {
    hostName = "${name}";
    networkmanager.enable = true;
    firewall.allowedTCPPorts = [];
    firewall.enable = true;
    # nftables.enable = true;
  };


  # ---------------------------------------------------------------------------
  #
  # ~ Audio
  #
  # ---------------------------------------------------------------------------

  # sound.enable = true;
  services.pipewire = {
    enable = true;
    pulse = {
      # package = unstablePkgs.pulseaudioFull;
      enable = true;
    };
    wireplumber = {
      # package = unstablePkgs.wireplumber;
      enable = true;
    };
    jack.enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
  };

  # Bluetooth
  hardware = {
    # https://nixos.wiki/wiki/Bluetooth
    bluetooth = {
      enable = true;
      package = unstablePkgs.bluez;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;
        };
      };
    };

    pulseaudio.enable = false;

    # pulseaudio.extraConfig = "
    #   load-module module-switch-on-connect
    #   load-module module-bluetooth-policy
    #   load-module module-bluetooth-discover
    # ";
  };


  # ---------------------------------------------------------------------------
  #
  # ~ Misc
  #
  # ---------------------------------------------------------------------------
  services = {
    openssh.enable = false;
    vnstat.enable = true;
    udev.packages = [ pkgs.qmk-udev-rules ];
  };

  # networking.extraHosts = ''
  #   127.0.0.1 monica.local
  # '';
  # services.monica = {
  #   # Disable SSL
  #   config.APP_ENV = pkgs.lib.mkForce "local";
  #   enable = true;
  #   # user = "noon";
  #   # group = "users";
  #   # dataDir = "/home/noon/.data/monica";
  #   hostname = "monica.local";
  #   appKeyFile = "/tmp/monica-key";
  #   nginx = {
  #     serverAliases = [
  #       "monica.local"
  #     ];
  #     forceSSL = false;
  #   };
  # };

  # From <https://kokada.capivaras.dev/blog/an-unordered-list-of-hidden-gems-inside-nixos/>
  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };
  services.dbus.implementation = "broker";

  virtualisation.docker = {
    package = unstablePkgs.docker;
    enable = true;
  };

  fonts = {
    packages = with unstablePkgs.pkgs; [
      nerdfonts
      noto-fonts-emoji
      noto-fonts-color-emoji
      raleway
      recursive
      source-code-pro
      source-sans-pro
      source-serif-pro
      symbola
      twitter-color-emoji
    ];
    enableDefaultPackages = true;
    fontconfig = {
      defaultFonts = {
        monospace = [ "iMWritingMono Nerd Font" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };


  # ---------------------------------------------------------------------------
  #
  # ~ Internationalisation / i18n
  #
  # ---------------------------------------------------------------------------
  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.utf8";


  # ---------------------------------------------------------------------------
  #
  # ~ Security
  #
  # ---------------------------------------------------------------------------
  services = {
    gnome.gnome-keyring.enable = true;
  };

  security = {
    rtkit.enable = true;
    pam.services.login.enableGnomeKeyring = true;
  };

  users.users.noon = {
    isNormalUser = true;
    description = "noon";
    extraGroups = [ "networkmanager" "wheel" "dialout" "audio" "docker" ];
  };

  users.users.gala = {
    isNormalUser = true;
    description = "gala";
    extraGroups = [ "networkmanager" "wheel" "dialout" "audio" "docker" ];
  };

  # ---------------------------------------------------------------------------
  #
  # ~ NixOS
  #
  # ---------------------------------------------------------------------------

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
