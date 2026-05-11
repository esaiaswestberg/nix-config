# NixOS configuration

This repository is the NixOS configuration for a single workstation named `loca`. It is structured as a flake-based system definition with a shared module layer, a host profile, and two Home Manager user profiles.

## Repository layout

- `flake.nix`: flake entrypoint and pinned inputs
- `flake.lock`: pinned dependency versions
- `hosts/loca`: machine-specific NixOS configuration
- `modules`: shared system modules grouped by concern
- `home/shared`: Home Manager defaults shared by both users
- `home/esaiaswestberg`: Home Manager overlay for the primary user
- `home/filippawestberg`: Home Manager overlay for the second user
- `secrets`: encrypted secrets and the bootstrap notes for them
- `scripts`: helper scripts, including the interactive bootstrap runner

## How the configuration is assembled

`flake.nix` defines the `loca` NixOS system and passes the host name and user names into the module graph. The host entrypoint in `hosts/loca/default.nix` imports the shared modules, the host-specific hardware files, and the Home Manager configuration for both accounts.

The split is intentional:

- `hosts/loca` owns machine-specific state such as disk layout, boot configuration, and any host-only overrides
- `modules` contains shared system behavior such as shell UX, networking, security, gaming, VPNs, Docker, and backups
- `home/shared` contains user-facing defaults that both accounts share
- `home/esaiaswestberg` and `home/filippawestberg` contain the per-user overlays that differ between accounts
- `secrets` holds the encrypted source file consumed by `sops-nix` plus the bootstrap guidance for creating it

## Module overview

- `modules/common.nix`: base system defaults, Nix settings, NetworkManager, firmware, and the core package set
- `modules/security.nix`: firewall and SSH policy
- `modules/users.nix`: the normal user accounts and their default groups
- `modules/shell.nix`: `zsh`, `oh-my-zsh`, Powerlevel10k, `tmux`, `fzf`, `zoxide`, `direnv`, and shell ergonomics
- `modules/input.nix`: Swedish keyboard layout and pointer/touchpad defaults
- `modules/desktop/cosmic.nix`: COSMIC desktop and greeter wiring
- `modules/desktop/ux.nix`: portals, fonts, Qt styling, and Wayland session defaults
- `modules/gaming.nix`: Steam, Gamemode, AppImage support, and graphics-related gaming flags
- `modules/docker.nix`: Docker daemon, Compose, Buildx, and user access
- `modules/ssh-client-keys.nix`: boot-time generation of the SSH client keys
- `modules/vpn.nix`: Tailscale autoconnect and ProtonVPN manual profiles
- `modules/backup.nix`: restic backups for system and home data
- `modules/secrets.nix`: `sops-nix` bootstrap and secret declarations

## User environment

`home/shared/default.nix` wires in the shared Home Manager modules:

- `home/shared/software.nix`: development tools and general-purpose CLI packages
- `home/shared/gaming.nix`: user-facing gaming launchers and helpers
- `home/shared/browser.nix`: shared MIME handling for browser defaults
- `home/shared/terminal.nix`: Alacritty and supporting clipboard/capture tools
- `home/shared/ssh.nix`: SSH host aliases and the default client identity file

`home/esaiaswestberg/default.nix` and `home/filippawestberg/default.nix` add the per-user browser choice on top of the shared base.

Both users get the same shell, SSH alias, terminal, gaming, and desktop-facing baseline, while the browser choice is user-specific.

## Current assumptions

- Flakes are enabled
- Home Manager is integrated into the system config
- COSMIC is the desktop target
- Docker runs as the standard system daemon
- Tailscale should auto-connect
- ProtonVPN should be available manually, but not auto-connect
- `sops-nix` manages the secrets needed for backups, Tailscale, and ProtonVPN
- both local users get encrypted password hashes from `sops-nix`
- both local users get a boot-time generated SSH client key if one is missing
- `filippawestberg` is a standard user without sudo access
- `esaiaswestberg` uses Zen Browser and `filippawestberg` uses Google Chrome as their default browser
- LUKS is the intended storage model, but the host-specific disk layout still needs to be filled in on the target machine

## Bootstrap status

The repository still contains placeholder host files:

- `hosts/loca/hardware-configuration.nix`
- `hosts/loca/luks.nix`
- `secrets/loca.yaml`

Those placeholders are intentional. They keep the repo shape stable while the real machine-specific disk and secret values are filled in later.

For a from-scratch install, use [`scripts/bootstrap.sh`](scripts/bootstrap.sh). It handles the disk layout, host hardware files, age key bootstrapping, and encrypted secret creation interactively. The manual steps in the docs remain as the fallback path.

## Setup guide

See [docs/setup.md](docs/setup.md) for the clean-system bootstrap flow.
