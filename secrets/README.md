# Secrets

This directory is reserved for encrypted secrets managed by `sops-nix`.

The workstation currently expects `secrets/workstation.yaml` to provide:

- `backup/restic/repository`
- `backup/restic/password`
- `backup/restic/ssh-key`

The age key is generated on the target machine at `/var/lib/sops-nix/key.txt`.
Encrypt the secrets file to that key once the machine has booted.

