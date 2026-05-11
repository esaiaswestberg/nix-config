# Clean System Setup

This is the exact bootstrap flow for the workstation named `loca`.

Prefer [`scripts/bootstrap.sh`](../scripts/bootstrap.sh) for a new machine. It asks for the required values, lays out the disk, writes the host files, and encrypts `secrets/loca.yaml` in one run. Keep the manual steps below as the fallback if you need to do the process by hand or debug one stage at a time.

You can preview the bootstrap with:

```bash
sudo ./scripts/bootstrap.sh --dry-run
```

If the script aborts after mounting or partitioning, unmount `/mnt`, close `cryptroot` if it is still open, and run the dry run again before retrying the full install.

## 0. Start from the installer

Boot the NixOS installer on the target machine and get a shell with root access.

Before this repository can evaluate cleanly, you need the real disk layout and the encrypted secrets file for the machine.

## 1. Identify the disks and mount points

List the block devices and filesystems:

```bash
lsblk -f
sudo blkid
```

If the root or boot disks are not obvious, inspect them before editing anything else.

You are looking for:

- the EFI system partition
- the root filesystem
- the encrypted partition, if the machine uses LUKS

## 2. Fill in the host hardware files

Replace the placeholder files in `hosts/loca`:

- `hardware-configuration.nix`
- `luks.nix`

If you are installing from the live system, run the generator and copy the result into the repo:

```bash
sudo nixos-generate-config
cp /etc/nixos/hardware-configuration.nix <repo-root>/hosts/loca/hardware-configuration.nix
```

If the repo is mounted somewhere else, copy it there instead.

Then edit `hosts/loca/luks.nix` so it contains the real disk UUIDs and mount targets for the encrypted storage on `loca`.

The repository will not evaluate until the root filesystem is defined in the host config.

If you want to sanity-check the host files before the first switch, run:

```bash
cd <repo-root>
nix flake check
```

## 3. Do the first rebuild

Once the hardware files are in place, run the first rebuild from the repo root:

```bash
cd <repo-root>
sudo nixos-rebuild switch --flake .#loca
```

You can use a build-only pass first if you want to confirm evaluation before switching:

```bash
cd <repo-root>
sudo nixos-rebuild build --flake .#loca
```

The first successful activation creates the `sops-nix` age key at:

```bash
/var/lib/sops-nix/key.txt
```

Export the public key from that file:

```bash
sudo age-keygen -y /var/lib/sops-nix/key.txt
```

Keep the resulting public key. You will use it to encrypt `secrets/loca.yaml`.

## 4. Encrypt the secrets

The repository expects `secrets/loca.yaml` to be encrypted for the machine key and to contain these secret paths:

- `backup/restic/repository`
- `backup/restic/password`
- `backup/restic/ssh-key`
- `users/esaiaswestberg/password-hash`
- `users/filippawestberg/password-hash`
- `tailscale/auth-key`
- `vpn/proton/env`

Create a temporary plaintext file with the values:

```bash
cat > /tmp/loca.secrets.yaml <<'EOF'
backup/restic/repository: sftp:user@backup.example.com:/srv/restic/loca
backup/restic/password: replace-me
backup/restic/ssh-key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  replace-me
  -----END OPENSSH PRIVATE KEY-----
users/esaiaswestberg/password-hash: "$y$j9T$replace-me"
users/filippawestberg/password-hash: "$y$j9T$replace-me"
tailscale/auth-key: tskey-auth-replace-me
vpn/proton/env: |
  PROTONVPN_WIREGUARD_PRIVATE_KEY=replace-me
  PROTONVPN_WIREGUARD_PUBLIC_KEY=replace-me
  PROTONVPN_WIREGUARD_ENDPOINT=replace-me
  PROTONVPN_IPV4_ADDRESS=replace-me
  PROTONVPN_DNS=replace-me
EOF
```

Then encrypt it to the public age key you extracted earlier:

```bash
AGE_PUBLIC_KEY="$(sudo age-keygen -y /var/lib/sops-nix/key.txt)"
sops --encrypt --age "$AGE_PUBLIC_KEY" /tmp/loca.secrets.yaml > <repo-root>/secrets/loca.yaml
rm /tmp/loca.secrets.yaml
```

If you need to edit the encrypted file later on the machine itself, use the private key on disk:

```bash
cd <repo-root>
sudo env SOPS_AGE_KEY_FILE=/var/lib/sops-nix/key.txt sops secrets/loca.yaml
```

Populate these fields:

- `backup/restic/repository`: the remote restic repository URL, for example an SFTP path
- `backup/restic/password`: the restic repository password
- `backup/restic/ssh-key`: the private SSH key used by root to reach the backup server
- `users/esaiaswestberg/password-hash`: the hashed password for the primary admin user
- `users/filippawestberg/password-hash`: the hashed password for the second standard user
- `tailscale/auth-key`: the Tailscale preauth key used for boot-time login
- `vpn/proton/env`: an encrypted environment file containing ProtonVPN WireGuard settings

The ProtonVPN environment file must provide:

- `PROTONVPN_WIREGUARD_PRIVATE_KEY`
- `PROTONVPN_WIREGUARD_PUBLIC_KEY`
- `PROTONVPN_WIREGUARD_ENDPOINT`
- `PROTONVPN_IPV4_ADDRESS`
- `PROTONVPN_DNS`

## 5. Rebuild after secrets are in place

Run the switch again so the decrypted secrets are written and the services can come up:

```bash
cd <repo-root>
sudo nixos-rebuild switch --flake .#loca
```

If you are changing only one file and want to check evaluation first:

```bash
cd <repo-root>
sudo nixos-rebuild build --flake .#loca
```

## 6. Verify the machine

Check the core services and profiles:

```bash
tailscale status
systemctl status restic-backups-loca.service
docker info
docker compose version
docker buildx version
nmcli connection show --active
```

What to expect:

- Tailscale should be connected automatically
- ProtonVPN should exist as a NetworkManager profile named `ProtonVPN`, but it should not autoconnect
- Docker should be available to the `esaiaswestberg` user without `sudo`
- Restic should be wired to run from `restic-backups-loca.timer`

If you want to inspect the timer:

```bash
systemctl status restic-backups-loca.timer
```

## 7. Day-to-day commands

Use these commands after the machine is configured:

```bash
sudo nixos-rebuild switch --flake .#loca
sudo env SOPS_AGE_KEY_FILE=/var/lib/sops-nix/key.txt sops secrets/loca.yaml
tailscale status
systemctl status restic-backups-loca.service
docker ps
docker compose up
```

The repository now expects both local users to use encrypted password hashes instead of plaintext bootstrap passwords, so set the hashes in `secrets/loca.yaml` before the first switch that creates the accounts.

The two users on the machine are:

- `esaiaswestberg`: admin user with `wheel`
- `filippawestberg`: standard user without admin access

To generate the password hashes, run `mkpasswd` from a disposable shell and paste the resulting hashes into the secret file:

```bash
nix shell nixpkgs#whois -c mkpasswd -m yescrypt
```

Run it once for each account, then place the two hash strings into `users/esaiaswestberg/password-hash` and `users/filippawestberg/password-hash` before encrypting `secrets/loca.yaml`.

To rotate a secret:

1. Open `secrets/loca.yaml` with `sops` and the machine age key.
2. Update the relevant secret value.
3. Save and close the file.
4. Rebuild with `sudo nixos-rebuild switch --flake .#loca`.

The host still has one bootstrap limitation: `hosts/loca/hardware-configuration.nix` and `hosts/loca/luks.nix` must be filled in on the target machine before the repo can evaluate cleanly.

## Recovery

If a bootstrap attempt fails before the final install:

1. Check whether `/mnt` is mounted and unmount it if necessary.
2. Close the `cryptroot` mapping if it is still open.
3. Re-run `sudo ./scripts/bootstrap.sh --dry-run` to confirm the environment is still sane.
4. Re-run the full bootstrap once the preflight checks pass.
