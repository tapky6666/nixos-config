{ config, lib, pkgs, ... }:
with lib;
let cfg = config.within.services.site;
in {
  options.within.services.site = {
    enable = mkEnableOption "Activates my personal website";
    useACME = mkEnableOption "Enables ACME for cert stuff";

    port = mkOption {
      type = types.port;
      default = 32837;
      example = 9001;
      description = "The port number site should listen on for HTTP traffic";
    };

    domain = mkOption {
      type = types.str;
      default = "site.akua";
      example = "fetsorn.website";
      description =
        "The domain name that nginx should check against for HTTP hostnames";
    };

    sockPath = mkOption rec {
      type = types.str;
      default = "/srv/within/run/site.sock";
      example = default;
      description = "The unix domain socket that site should listen on";
    };
  };

  config = mkIf cfg.enable {

    users.users.site = {
      createHome = true;
      description = "github.com/fetsorn/site";
      isSystemUser = true;
      group = "within";
      home = "/srv/within/site";
      extraGroups = [ "keys" ];
    };

    within.secrets.site = {
      source = ./secrets/site.env;
      dest = "/srv/within/site/.env";
      owner = "site";
      group = "within";
      permissions = "0400";
    };

    systemd.services.site = {
      wantedBy = [ "multi-user.target" ];
      after = [ "site-key.service" ];
      wants = [ "site-key.service" ];

      serviceConfig = {
        User = "site";
        Group = "within";
        Restart = "on-failure";
        WorkingDirectory = "/srv/within/site";
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
        export $(cat /srv/within/site/.env | xargs)
        export SOCKPATH=${cfg.sockPath}
        export PORT=${toString cfg.port}
        export DOMAIN=${toString cfg.domain}
        cd ${site}
        exec ${site}/bin/site
      '';
    };

    services.nginx.virtualHosts."site" = {
      serverName = "${cfg.domain}";
      locations."/" = {
        proxyPass = "http://unix:${toString cfg.sockPath}";
        proxyWebsockets = true;
      };
      forceSSL = cfg.useACME;
      useACMEHost = "fetsorn.website";
      extraConfig = ''
        access_log /var/log/nginx/site.access.log;
      '';
    };
  };
}

