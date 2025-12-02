{ name, config, pkgs, ... }:
{
  # See: https://nixos.wiki/wiki/Fwupd
  #
  #   fwupdmgr refresh
  #   fwupdmgr get-updates
  #   fwupdmgr update
  #
  services.fwupd.enable = true;

  # Screen locking
  programs.slock.enable = true;

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
        # isd # interactive systemd
        acpi # For power information
        alsa-utils # Music control
        arandr # Graphical xrandr
        autoconf # ???
        automake # ???
        bashmount # Mount disks via TUI
        binutils # ???
        bluetui
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
        xxd
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
        fq # jq for binary data
        tcpdump # For working with/creating pcaps
        (google-cloud-sdk.withExtraComponents
          (with google-cloud-sdk.components; [
            gke-gcloud-auth-plugin
            gsutil
            kubectl
          ])
        )
        gh-gfm-preview # GitHub-format Markdown Preview
        certbot # Generate SSL certs
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
        # lychee # Markdown link checker
        magic-wormhole-rs # magic-wormhole for sending files
        nix-prefetch-git # Get nix hashes
        nix-tree # Browse nix dependency graphs
        nvd # Nix package version diff
        openssl # Sometimes useful
        ripgrep # File searcher
        sd # Modern find and replace
        yq # jq for yaml
        kdePackages.kate # simple text editor
        jujutsu
        mergiraf
        miniserve # Simple HTTP server
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
        # gimp-with-plugins # For making memes
        # glow # Terminal Markdown renderer
        hunspell # Spelling
        hunspellDicts.en-gb-ise # Spelling
        imagemagick # Essential image tools
        inkscape # Meme creation
        lyx # For writing WYSIWYG TeX
        meld # Visual diff tool
        nautilus # File browser
        nix-output-monitor # Nicer build info when nixing
        kdePackages.okular # PDF viewing
        optipng # Optimise pngs
        pandoc # Occasionally useful
        pkgs.gedit # When times get desperate
        rofimoji # Emoji picker
        texlive.combined.scheme-full # Full TeX environment
        flameshot # Take screenshots
        vokoscreen-ng # Screen recording for videos
        vlc # For videos
        xournalpp # PDF writing
        exiftool # Image Metadata
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
      enable = true;
    };
    wireplumber = {
      enable = true;
    };
    jack.enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
  };
  services.pulseaudio.enable = false;

  # Bluetooth
  hardware = {
    # https://nixos.wiki/wiki/Bluetooth
    bluetooth = {
      enable = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;
        };
        Policy = {
          AutoEnable = true;
        };
      };
    };
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
    enable = true;
  };

  fonts = {
    packages = with pkgs; [
      nerd-fonts.im-writing
      noto-fonts-color-emoji
      raleway
      recursive
      # source-code-pro
      # source-sans-pro
      # source-serif-pro
      # symbola
      twitter-color-emoji
      # julia-mono
      # monaspace
      # cartograph # Paid
      # fragment-mono
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
  # time.timeZone = "America/Mexico_City";
  i18n.defaultLocale = "en_GB.UTF-8";


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
}
