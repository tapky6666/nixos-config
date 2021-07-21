{ config, lib, pkgs, ... }:
with lib;
let cfg = config.within.services.xesite;
in {
  options.within.services.xesite = {
    enable = mkEnableOption "Activates my personal website";
    useACME = mkEnableOption "Enables ACME for cert stuff";

    port = mkOption {
      type = types.port;
      default = 32837;
      example = 9001;
      description = "The port number xesite should listen on for HTTP traffic";
    };

    domain = mkOption {
      type = types.str;
      default = "xesite.akua";
      example = "christine.website";
      description =
        "The domain name that nginx should check against for HTTP hostnames";
    };

    sockPath = mkOption rec {
      type = types.str;
      default = "/srv/within/run/xesite.sock";
      example = default;
      description = "The unix domain socket that xesite should listen on";
    };
  };

  config = mkIf cfg.enable {

    users.users.xesite = {
      createHome = true;
      description = "github.com/Xe/site";
      isSystemUser = true;
      group = "within";
      home = "/srv/within/xesite";
      extraGroups = [ "keys" ];
    };

    within.secrets.xesite = {
      source = ./secrets/xesite.env;
      dest = "/srv/within/xesite/.env";
      owner = "xesite";
      group = "within";
      permissions = "0400";
    };

    systemd.services.xesite = {
      wantedBy = [ "multi-user.target" ];
      after = [ "xesite-key.service" ];
      wants = [ "xesite-key.service" ];

      serviceConfig = {
        User = "xesite";
        Group = "within";
        Restart = "on-failure";
        WorkingDirectory = "/srv/within/xesite";
        RestartSec = "30s";
        Type = "notify";

        # Security
        CapabilityBoundingSet = "";
        DeviceAllow = [ ];
        NoNewPrivileges = "true";
        ProtectControlGroups = "true";
        ProtectClock = "true";
        PrivateDevices = "true";
        PrivateUsers = "true";
        ProtectHome = "true";
        ProtectHostname = "true";
        ProtectKernelLogs = "true";
        ProtectKernelModules = "true";
        ProtectKernelTunables = "true";
        ProtectSystem = "true";
        ProtectProc = "invisible";
        RemoveIPC = "true";
        RestrictSUIDSGID = "true";
        RestrictRealtime = "true";
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "~@reboot"
          "~@module"
          "~@mount"
          "~@swap"
          "~@resources"
          "~@cpu-emulation"
          "~@obsolete"
          "~@debug"
          "~@privileged"
        ];
        UMask = "007";
      };

      script = let site = pkgs.callPackage ./githubsite.nix { };
      in ''
        export $(cat /srv/within/xesite/.env | xargs)
        export SOCKPATH=${cfg.sockPath}
        export PORT=${toString cfg.port}
        export DOMAIN=${toString cfg.domain}
        cd ${site}
        exec ${site}/bin/xesite
      '';
    };

    services.nginx.virtualHosts."xesite" = {
      serverName = "${cfg.domain}";
      locations."/" = {
        proxyPass = "http://unix:${toString cfg.sockPath}";
        proxyWebsockets = true;
      };
      forceSSL = cfg.useACME;
      useACMEHost = "fetsorn.website";
      extraConfig = ''
        access_log /var/log/nginx/xesite.access.log;
      '';
    };
  };
}

