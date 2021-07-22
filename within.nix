{ config, ... }:

let
  paths = [
    "/srv"
    "/var/lib/acme"
    "/var/lib/mysql"
    "/run/keys"
  ];
  exclude = [
    # temporary files created by cargo
    "**/target"
    "/srv/backup"
    "/var/lib/docker"
    "/var/lib/systemd"
    "/var/lib/libvirt"
    "'**/.cache'"
    "'**/.nix-profile'"
    "'**/.elm'"
    "'**/.emacs.d'"
  ];
in {

  within = {

    services = {

      # webapps
      site = {
        enable = true;
        useACME = true;
        domain = "fetsorn.website";
      };
    };
  };

}

