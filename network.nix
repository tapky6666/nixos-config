{
  "droplet" = { pkgs, modulesPath, lib, name, ... }: {
    imports = lib.optional (builtins.pathExists ./do-userdata.nix) ./do-userdata.nix ++ [
      (modulesPath + "/virtualisation/digital-ocean-config.nix")
      ./acme.nix
      ./crypto.nix
      ./within.nix
      ./site.nix
    ];

    deployment.targetHost = "139.59.35.172";
    deployment.targetUser = "root";

    networking.hostName = name;

    networking.usePredictableInterfaceNames = false;

    nix = {
      autoOptimiseStore = true;
      useSandbox = true;
      binaryCaches          = [
        "https://hydra.iohk.io"
        "https://iohk.cachix.org"
        "https://nix-community.cachix.org"
      ];
      binaryCachePublicKeys = [
        "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
        "iohk.cachix.org-1:DpRUyj7h7V830dp/i6Nti+NEO2/nhblbov/8MW7Rqoo="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      trustedUsers = [ "root" "fetsorn" ];
    };

    security.pam.loginLimits = [{
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "unlimited";
    }];
    systemd.services.within-homedir-setup = {
      description = "Creates homedirs for /srv/within services";
      wantedBy = [ "multi-user.target" ];

      serviceConfig.Type = "oneshot";

      script = with pkgs; ''
        ${coreutils}/bin/mkdir -p /srv/within
        ${coreutils}/bin/chown root:within /srv/within
        ${coreutils}/bin/chmod 775 /srv/within
        ${coreutils}/bin/mkdir -p /srv/within/run
        ${coreutils}/bin/chown root:within /srv/within/run
        ${coreutils}/bin/chmod 770 /srv/within/run
      '';
    };
    services.journald.extraConfig = ''
      SystemMaxUse=100M
      MaxFileSec=7day
    '';

    services.resolved = {
      enable = true;
      dnssec = "false";
    };

    services.lorri.enable = true;
    systemd.network = {
      enable = true;
    };

    users.groups.within = { };

    systemd.services.nginx.serviceConfig.SupplementaryGroups = "within";
    services.nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      statusPage = true;
      enableReload = true;
      commonHttpConfig = ''
        set_real_ip_from 103.21.244.0/22;
        set_real_ip_from 103.22.200.0/22;
        set_real_ip_from 103.31.4.0/22;
        set_real_ip_from 104.16.0.0/13;
        set_real_ip_from 104.24.0.0/14;
        set_real_ip_from 108.162.192.0/18;
        set_real_ip_from 131.0.72.0/22;
        set_real_ip_from 141.101.64.0/18;
        set_real_ip_from 162.158.0.0/15;
        set_real_ip_from 172.64.0.0/13;
        set_real_ip_from 173.245.48.0/20;
        set_real_ip_from 188.114.96.0/20;
        set_real_ip_from 190.93.240.0/20;
        set_real_ip_from 197.234.240.0/22;
        set_real_ip_from 198.41.128.0/17;
        set_real_ip_from 2400:cb00::/32;
        set_real_ip_from 2606:4700::/32;
        set_real_ip_from 2803:f800::/32;
        set_real_ip_from 2405:b500::/32;
        set_real_ip_from 2405:8100::/32;
        set_real_ip_from 2c0f:f248::/32;
        set_real_ip_from 2a06:98c0::/29;
        real_ip_header CF-Connecting-IP;
      '';
    };

    services.mysql = {
      enable = true;
      package = pkgs.mariadb;
      bind = "127.0.0.1";
    };

    networking.firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 1965 6667 6697 8009 8000 8080 3030 ];
      allowedUDPPorts = [ 41641 51822 51820 ];

      allowedUDPPortRanges = [{
        from = 32768;
        to = 65535;
      }];
    };

    environment.systemPackages = with pkgs; [
      cabal-install
      emacs
      fd
      ghc
      ripgrep
      tmux
      unzip
      vim
      wget
    ];

    users.users.fetsorn = {
      isNormalUser = true;
      extraGroups = [ "wheel" "docker"];
    };

    virtualisation.docker.enable = true;

    nixpkgs.config.allowUnfree = true;

  };
}

