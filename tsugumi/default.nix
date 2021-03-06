# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports = [
    ../modules
    ./hardware-configuration.nix
    ../modules/plex.nix
    # ../disnix/production/tsugumi-config.nix
    <nixpkgs/nixos/modules/profiles/headless.nix>
    # <nixpkgs/nixos/modules/profiles/hardened.nix>
    # ../modules/powersave.nix
  ];

  me = {
    propagateNix = true;
    virtualisation.enable = true;
  };

  services.zrepl = {
    enable = true;
    sink.madoka = {
      rootFs = "stash/zrepl";
      openFirewall = true;
    };
  };


  # Work around #1915
  boot.kernel.sysctl."user.max_user_namespaces" = 100;

  # Use GRUB, with fallbacks. Once fallbacks are implemented.
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub = {
    enable = true;
    zfsSupport = true;
    efiSupport = true;
    device = "nodev";
  };

  # Power management:
  #services.thermald.enable = true;
  powerManagement.enable = true;
  powerManagement.powertop.enable = true;

  ## Networking ##
  networking.hostName = "tsugumi";
  networking.hostId = "3b3fc025";
  networking.usePredictableInterfaceNames = false;

  networking.firewall.allowedTCPPorts = [
    80 443   # Web-server
    6986     # rtorrent
    139 445  # Samba
  ];
  networking.firewall.allowedUDPPorts = [
    6987 6881  # rtorrent
    10401      # Wireguard
    27016      # Space Engineers
    34197      # Factorio
    137 138    # Samba
  ];
  services.unifi.enable = true;


  # Wireguard link between my machines
  networking.wireguard = {
    interfaces.wg0 = {
      ips = [ "10.40.0.1/24" ];
      listenPort = 10401;
      peers = [
        # Kaho
        {
          allowedIPs = [ "10.40.0.5/32" ];
          publicKey = "AajvMFJZQptkunsC2NYbwy6Ig7ly64QO1K94kvJyxRA=";
        }
        # Madoka
        {
          allowedIPs = [ "10.40.0.2/32" ];
          endpoint = "madoka.brage.info:10401";
          persistentKeepalive = 30;
          publicKey = "kTxN9HAb73WDJXRAq704cKs/WS5VJ23oSgaAWeVrvRQ=";
        }
        # Saya
        {
          allowedIPs = [ "10.40.0.3/32" ];
          endpoint = "saya.brage.info:10401";
          persistentKeepalive = 30;
          publicKey = "VcQ9no2+2hSTa9BO2fEpickKC50ibWp5uo0HrNBFmk8=";
        }
        # Tromso
        {
          allowedIPs = [ "10.40.0.4/32" ];
          persistentKeepalive = 30;
          publicKey = "F8V/UkXUxnb+RCF3UePpJSO1opoSORDFv+dI2HqFQW8=";
        }
      ];
      privateKeyFile = "/secrets/wg.key";
    };
  };

  ## Services ##
  # Samba
  services.samba = {
    enable = true;
    extraConfig = ''
      map to guest = bad user

      [homes]
      read only = no
    '';
  };
  # users.users.smbguest = {
  #     name = "smbguest";
  #     uid = config.ids.uids.smbguest;
  #     description = "SMB guest user";
  # };

  # Nginx
  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    sslDhparam = ./nginx/dhparams.pem;
    appendHttpConfig = ''
      add_header Strict-Transport-Security "max-age=31536000; includeSubdomains";
      add_header X-Clacks-Overhead "GNU Terry Pratchett";
    '';
    virtualHosts = let base = x: {
      forceSSL = true;
      enableACME = true;
    } // x; in {
      "brage.info" = base {
        default = true;
        serverAliases = [ "tsugumi.brage.info" "www.brage.info" ];
        locations."/".root = "/home/svein/web/";
        extraConfig = "autoindex on;";
      };
      "ar-innna.brage.info" = base {
        locations."/" = {
          root = "/home/aquagon/web/";
          extraConfig = "autoindex on;";
        };
      };
      "wiki.sufficientvelocity.com" = base {
        locations."/".proxyPass = "http://127.0.0.1:3300";
      };
    };
  };

  users.include = ["pl" "aquagon" "will" "snowfire"];
}
