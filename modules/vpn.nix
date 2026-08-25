{ config, ... }:
{
  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "client";
    authKeyFile = config.sops.secrets."tailscale/auth-key".path;
    authKeyParameters.preauthorized = true;
  };

  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  networking.networkmanager.ensureProfiles = {
    environmentFiles = [
      config.sops.secrets."vpn/proton/env".path
    ];

    profiles.protonvpn = {
      connection = {
        id = "ProtonVPN";
        type = "wireguard";
        autoconnect = false;
        interface-name = "protonvpn";
      };

      wireguard = {
        private-key = "$PROTONVPN_WIREGUARD_PRIVATE_KEY";
        peer-routes = true;
      };

      "wireguard-peer.$PROTONVPN_WIREGUARD_PUBLIC_KEY" = {
        endpoint = "$PROTONVPN_WIREGUARD_ENDPOINT";
        allowed-ips = "0.0.0.0/0;::/0;";
        persistent-keepalive = 25;
      };

      ipv4 = {
        method = "manual";
        address1 = "$PROTONVPN_IPV4_ADDRESS";
        dns = "$PROTONVPN_DNS";
        dns-priority = -50;
        never-default = false;
      };

      ipv6 = {
        method = "disabled";
        never-default = true;
      };
    };
  };
}
