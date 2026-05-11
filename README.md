# NixOS configuration

This repository is the NixOS configuration for a single workstation. It is structured as a flake-based system definition with a shared module layer, a workstation host profile, and a Home Manager user profile.

## Repository layout

- `flake.nix`: flake entrypoint and pinned inputs
- `flake.lock`: pinned dependency versions
- `hosts/workstation`: machine-specific NixOS configuration
- `modules`: shared system modules grouped by concern
- `home/dev`: Home Manager configuration for the default user
- `secrets`: encrypted secrets and the bootstrap notes for them

## How the configuration is assembled

`flake.nix` defines the `workstation` NixOS system and passes the host name and user name into the module graph. The host entrypoint in `hosts/workstation/default.nix` imports the shared modules, the workstation-specific hardware files, and the Home Manager configuration.

The split is intentional:

- `hosts/workstation` owns machine-specific state such as disk layout, boot configuration, and any host-only overrides
- `modules` contains shared system behavior such as shell UX, networking, security, gaming, VPNs, Docker, and backups
- `home/dev` contains user-facing packages and terminal configuration that should follow the user rather than the machine
- `secrets` holds the encrypted source file consumed by `sops-nix` plus the bootstrap guidance for creating it

## Module overview

- `modules/common.nix`: base system defaults, Nix settings, NetworkManager, firmware, and the core package set
- `modules/security.nix`: firewall and SSH policy
- `modules/users.nix`: the normal user account and its default groups
- `modules/shell.nix`: `zsh`, `tmux`, `fzf`, `zoxide`, `direnv`, `starship`, and shell ergonomics
- `modules/input.nix`: Swedish keyboard layout and pointer/touchpad defaults
- `modules/desktop/cosmic.nix`: COSMIC desktop and greeter wiring
- `modules/desktop/ux.nix`: portals, fonts, Qt styling, and Wayland session defaults
- `modules/gaming.nix`: Steam, Gamemode, AppImage support, and graphics-related gaming flags
- `modules/docker.nix`: Docker daemon, Compose, Buildx, and user access
- `modules/vpn.nix`: Tailscale autoconnect and ProtonVPN manual profiles
- `modules/backup.nix`: restic backups for system and home data
- `modules/secrets.nix`: `sops-nix` bootstrap and secret declarations

## User environment

`home/dev/default.nix` wires in three Home Manager modules:

- `home/dev/software.nix`: development tools and general-purpose CLI packages
- `home/dev/gaming.nix`: user-facing gaming launchers and helpers
- `home/dev/terminal.nix`: Alacritty and supporting clipboard/capture tools

## Current assumptions

- Flakes are enabled
- Home Manager is integrated into the system config
- COSMIC is the desktop target
- Docker runs as the standard system daemon
- Tailscale should auto-connect
- ProtonVPN should be available manually, but not auto-connect
- `sops-nix` manages the secrets needed for backups, Tailscale, and ProtonVPN
- LUKS is the intended storage model, but the workstation-specific disk layout still needs to be filled in on the target machine

## Bootstrap status

The repository still contains placeholder host files:

- `hosts/workstation/hardware-configuration.nix`
- `hosts/workstation/luks.nix`
- `secrets/workstation.yaml`

Those placeholders are intentional. They keep the repo shape stable while the real machine-specific disk and secret values are filled in later.

## Setup guide

See [docs/setup.md](docs/setup.md) for the clean-system bootstrap flow.
