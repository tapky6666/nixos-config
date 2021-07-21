{ pkgs, ... }:

let
  creds = pkgs.writeTextFile {
    name = "cloudflare.env";
    text = builtins.readFile ./secrets/acme-cf.env;
  };

  extraLegoFlags = [ "--dns.resolvers=8.8.8.8:53" ];

in {
  security.acme.email = "me@fetsorn.website";
  security.acme.acceptTerms = true;

  security.acme.certs."fetsorn.website" = {
    group = "nginx";
    email = "me@fetsorn.website";
    dnsProvider = "cloudflare";
    credentialsFile = "${creds}";
    extraDomainNames = [ "*.fetsorn.website" ];
    inherit extraLegoFlags;
  };
}

