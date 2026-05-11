# Secrets

This directory holds the encrypted secrets consumed by `sops-nix` on `loca`.

## Files

- `secrets/loca.yaml`: encrypted secret source file for the host
- `secrets/README.md`: this guide

## How the secrets file is used

`modules/secrets.nix` points `sops-nix` at `secrets/loca.yaml` and decrypts the values on the target machine.

The machine generates its age key at:

```bash
/var/lib/sops-nix/key.txt
```

The public key for encryption comes from:

```bash
sudo age-keygen -y /var/lib/sops-nix/key.txt
```

## Secret paths in `secrets/loca.yaml`

### `backup/restic/repository`

The restic repository URL.

Use this for the remote backup destination, for example an SFTP path such as:

```text
sftp:user@backup.example.com:/srv/restic/loca
```

This value must be reachable from the machine and writable by the SSH key below.

### `backup/restic/password`

The restic repository password.

This is the encryption password for the restic repository itself. It is separate from the SSH key used to reach the backup server.

### `backup/restic/ssh-key`

The private SSH key used by `restic` to connect to the remote backup host.

The module writes this secret to:

```bash
/root/.ssh/id_ed25519
```

That key should be allowed to log in to the backup server without prompting.

### `users/esaiaswestberg/password-hash`

The hashed password for the primary admin user.

This should be a standard Linux password hash string, for example a hash generated with `mkpasswd` or another password hashing tool. The file should contain the hash only, not plaintext.

### `users/filippawestberg/password-hash`

The hashed password for the second standard user.

This uses the same format as the primary user hash, but it can be a different password.

### `tailscale/auth-key`

The Tailscale preauth key.

This is the machine key used for automatic boot-time registration so Tailscale can connect without a manual `tailscale up`.

### `vpn/proton/env`

An encrypted environment file for ProtonVPN's WireGuard profile.

It must define:

- `PROTONVPN_WIREGUARD_PRIVATE_KEY`
- `PROTONVPN_WIREGUARD_PUBLIC_KEY`
- `PROTONVPN_WIREGUARD_ENDPOINT`
- `PROTONVPN_IPV4_ADDRESS`
- `PROTONVPN_DNS`

The module reads that file into NetworkManager as the manual-only `ProtonVPN` profile.

## Editing workflow

If you are creating the file from scratch, write the plaintext values into a temporary file and encrypt it with the machine's age public key:

```bash
cd <repo-root>
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
AGE_PUBLIC_KEY="$(sudo age-keygen -y /var/lib/sops-nix/key.txt)"
sops --encrypt --age "$AGE_PUBLIC_KEY" /tmp/loca.secrets.yaml > secrets/loca.yaml
rm /tmp/loca.secrets.yaml
```

If the file already exists, edit it on the machine with:

```bash
cd <repo-root>
sudo env SOPS_AGE_KEY_FILE=/var/lib/sops-nix/key.txt sops secrets/loca.yaml
```

To add or update a secret later:

1. Open `secrets/loca.yaml` with `sops` and the machine age key.
2. Change the relevant value.
3. Save the file.
4. Rebuild with `sudo nixos-rebuild switch --flake .#loca`.

## Bootstrap order

1. Install or boot the machine.
2. Fix `hosts/loca/hardware-configuration.nix` and `hosts/loca/luks.nix`.
3. Run the first `nixos-rebuild switch`.
4. Read `/var/lib/sops-nix/key.txt`.
5. Encrypt `secrets/loca.yaml` to that key.
6. Rebuild again so the secrets are available to `restic`, the two local users, `tailscale`, and `NetworkManager`.

## Notes

- Keep this file encrypted at rest.
- Do not commit plaintext credentials.
- The repository currently expects all host secrets to live in `secrets/loca.yaml`.
