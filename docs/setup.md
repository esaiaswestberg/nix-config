# Clean System Setup

This guide describes how to bring the workstation named `loca` up on a clean NixOS installation.

## 1. Install NixOS

Start from a normal NixOS installation on the target machine.

The key requirement is that the machine has the right hardware and storage details available before this repository can evaluate fully.

## 2. Fill in the host hardware files

Replace the placeholder files in `hosts/loca`:

- `hardware-configuration.nix`
- `luks.nix`

Use the generated hardware configuration from the installer or from `nixos-generate-config` on the target machine. Populate the root filesystem and encrypted disk configuration with the real device UUIDs and mount points for `loca`.

The repository will not evaluate cleanly until the root filesystem is defined.

## 3. Rebuild once to bootstrap `sops-nix`

After the hardware and disk configuration is correct, run a first rebuild on the target machine. That initial activation creates the age key used by `sops-nix` at:

```bash
/var/lib/sops-nix/key.txt
```

Extract the public key with:

```bash
age-keygen -y /var/lib/sops-nix/key.txt
```

## 4. Encrypt the secrets

The repository expects `secrets/loca.yaml` to contain encrypted entries for:

- `backup/restic/repository`
- `backup/restic/password`
- `backup/restic/ssh-key`
- `tailscale/auth-key`
- `vpn/proton/env`

The ProtonVPN file is an encrypted environment file containing:

- `PROTONVPN_WIREGUARD_PRIVATE_KEY`
- `PROTONVPN_WIREGUARD_PUBLIC_KEY`
- `PROTONVPN_WIREGUARD_ENDPOINT`
- `PROTONVPN_IPV4_ADDRESS`
- `PROTONVPN_DNS`

The restic entries are:

- the remote repository URL
- the repository password
- the SSH private key used to reach the backup host

The Tailscale key is the auth key used for automatic boot-time registration.

## 5. Rebuild `loca`

After the secrets are in place, rebuild the system:

```bash
sudo nixos-rebuild switch --flake .#loca
```

If you are iterating on the config, use:

```bash
sudo nixos-rebuild build --flake .#loca
```

before switching.

## 6. Verify the major services

After the rebuild, verify the expected services and tools:

- `tailscale status`
- `systemctl status restic-backups-loca.service`
- `docker info`
- `docker compose version`
- `docker buildx version`

ProtonVPN should appear as a NetworkManager profile but stay disconnected until you enable it manually.

## 7. Day-to-day operation

- Tailscale should auto-connect at boot once the auth key is present.
- ProtonVPN should stay manual-only.
- Docker should be available to the `esaiaswestberg` user without `sudo`.
- Backups should run daily through the restic timer.

If you need to change secrets later, edit the encrypted `secrets/loca.yaml` and re-run the rebuild on the target machine.
