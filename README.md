# NixOS configuration

This repository is a starter NixOS flake for a single machine.

## Layout

- `flake.nix`: flake entrypoint and pinned inputs
- `hosts/workstation`: host-specific configuration
- `modules`: shared system modules
- `home/dev`: Home Manager configuration for the default user

## Current assumptions

- Nix flakes are enabled
- Home Manager is integrated into the NixOS configuration
- COSMIC is the desktop target
- LUKS is the intended storage model, but the host-specific disk details still need to be filled in for the target machine
- `sops-nix` is wired in so encrypted secrets can be added later without changing the repo shape

## Next step

On the target machine, replace the placeholder hardware and storage files with the generated hardware configuration and the real encrypted-root settings for that machine.

