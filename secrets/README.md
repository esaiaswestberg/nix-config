# Secrets

This directory is reserved for encrypted secrets managed by `sops-nix`.

The `loca` host currently expects `secrets/loca.yaml` to provide:

- `backup/restic/repository`
- `backup/restic/password`
- `backup/restic/ssh-key`
- `tailscale/auth-key`
- `vpn/proton/env`

`vpn/proton/env` should be an encrypted environment file containing:

- `PROTONVPN_WIREGUARD_PRIVATE_KEY`
- `PROTONVPN_WIREGUARD_PUBLIC_KEY`
- `PROTONVPN_WIREGUARD_ENDPOINT`
- `PROTONVPN_IPV4_ADDRESS`
- `PROTONVPN_DNS`

The age key is generated on the target machine at `/var/lib/sops-nix/key.txt`.
Encrypt the secrets file to that key once the machine has booted.
