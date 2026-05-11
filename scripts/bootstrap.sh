#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

HOST_NAME="loca"
PRIMARY_USER="esaiaswestberg"
SECONDARY_USER="filippawestberg"
TARGET_ROOT="/mnt"
REPO_ROOT="${REPO_ROOT:-$(pwd)}"

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

log() {
  printf '%s\n' "$*"
}

require_root() {
  [[ ${EUID:-$(id -u)} -eq 0 ]] || die "run this script as root"
}

require_repo_root() {
  [[ -f "$REPO_ROOT/flake.nix" ]] || die "REPO_ROOT must point at the nix-config repo root"
}

prompt() {
  local label="$1"
  local default_value="${2:-}"
  local value
  if [[ -n "$default_value" ]]; then
    read -r -p "$label [$default_value]: " value
    printf '%s' "${value:-$default_value}"
  else
    read -r -p "$label: " value
    printf '%s' "$value"
  fi
}

prompt_secret() {
  local label="$1"
  local value
  read -rs -p "$label: " value
  printf '\n'
  printf '%s' "$value"
}

prompt_secret_confirm() {
  local label="$1"
  local first second
  first="$(prompt_secret "$label")"
  second="$(prompt_secret "confirm $label")"
  [[ "$first" == "$second" ]] || die "values did not match for: $label"
  printf '%s' "$first"
}

prompt_multiline() {
  local label="$1"
  local line content=""
  printf '%s\n' "$label"
  printf '%s\n' "Paste the value, then type EOF on its own line."
  while IFS= read -r line; do
    [[ "$line" == "EOF" ]] && break
    content+="${line}"$'\n'
  done
  printf '%s' "${content%$'\n'}"
}

confirm_overwrite() {
  local path="$1"
  if [[ -e "$path" ]]; then
    confirm "$path already exists. Overwrite it?"
  fi
}

confirm() {
  local message="$1"
  local reply
  read -r -p "$message [type YES to continue]: " reply
  [[ "$reply" == "YES" ]] || die "aborted"
}

command_or_nix_shell() {
  local package="$1"
  shift
  if command -v "$1" >/dev/null 2>&1; then
    "$@"
  else
    nix shell "nixpkgs#$package" -c "$@"
  fi
}

partition_path() {
  local disk="$1"
  local number="$2"
  if [[ "$disk" =~ [0-9]$ ]]; then
    printf '%sp%s' "$disk" "$number"
  else
    printf '%s%s' "$disk" "$number"
  fi
}

hash_password() {
  local password="$1"
  if command -v mkpasswd >/dev/null 2>&1; then
    printf '%s' "$password" | mkpasswd -m yescrypt
  elif command -v openssl >/dev/null 2>&1; then
    printf '%s' "$password" | openssl passwd -6 -stdin
  else
    printf '%s' "$password" | command_or_nix_shell whois mkpasswd -m yescrypt
  fi
}

cleanup() {
  if [[ -n "${luks_key_file:-}" && -f "${luks_key_file:-}" ]]; then
    shred -u "$luks_key_file" || true
  fi
  if [[ -n "${tmp_secrets:-}" && -f "${tmp_secrets:-}" ]]; then
    shred -u "$tmp_secrets" || true
  fi
  if mountpoint -q "$TARGET_ROOT"; then
    umount -R "$TARGET_ROOT" || true
  fi
  if cryptsetup status cryptroot >/dev/null 2>&1; then
    cryptsetup close cryptroot || true
  fi
}

trap cleanup EXIT

require_root
require_repo_root

log "Repository root: $REPO_ROOT"
log "Target host: $HOST_NAME"
log "Primary user: $PRIMARY_USER"
log "Secondary user: $SECONDARY_USER"

disk="$(prompt "Target disk (for example /dev/nvme0n1)")"
[[ -b "$disk" ]] || die "not a block device: $disk"

log ""
log "Current block devices:"
lsblk -dpno NAME,SIZE,MODEL "$disk" || true

confirm "This will erase $disk and create a new GPT + LUKS layout"

luks_passphrase="$(prompt_secret_confirm "LUKS passphrase")"
primary_password="$(prompt_secret_confirm "Password for $PRIMARY_USER")"
secondary_password="$(prompt_secret_confirm "Password for $SECONDARY_USER")"

restic_repository="$(prompt "Restic repository URL" "sftp:user@backup.example.com:/srv/restic/loca")"
restic_password="$(prompt_secret_confirm "Restic repository password")"
backup_ssh_key="$(prompt_multiline "Paste the backup SSH private key")"
tailscale_auth_key="$(prompt_secret_confirm "Tailscale auth key")"
proton_private_key="$(prompt_secret_confirm "ProtonVPN WireGuard private key")"
proton_public_key="$(prompt_secret_confirm "ProtonVPN WireGuard public key")"
proton_endpoint="$(prompt "ProtonVPN WireGuard endpoint")"
proton_ipv4_address="$(prompt "ProtonVPN IPv4 address")"
proton_dns="$(prompt "ProtonVPN DNS server")"

boot_part="$(partition_path "$disk" 1)"
root_part="$(partition_path "$disk" 2)"

log ""
log "Partitioning $disk"
sgdisk --zap-all "$disk"
parted -s "$disk" mklabel gpt
parted -s "$disk" mkpart ESP fat32 1MiB 513MiB
parted -s "$disk" set 1 esp on
parted -s "$disk" mkpart cryptroot 513MiB 100%
partprobe "$disk" || true
udevadm settle

log "Formatting EFI and LUKS partitions"
mkfs.fat -F 32 -n EFI "$boot_part"

luks_key_file="$(mktemp)"
chmod 600 "$luks_key_file"
printf '%s' "$luks_passphrase" > "$luks_key_file"
cryptsetup luksFormat --type luks2 --batch-mode --key-file "$luks_key_file" "$root_part"
cryptsetup open --key-file "$luks_key_file" "$root_part" cryptroot
shred -u "$luks_key_file"

mkfs.ext4 -L nixos /dev/mapper/cryptroot

mkdir -p "$TARGET_ROOT"
mount /dev/mapper/cryptroot "$TARGET_ROOT"
mkdir -p "$TARGET_ROOT/boot"
mount "$boot_part" "$TARGET_ROOT/boot"

log "Generating hardware configuration"
command_or_nix_shell nixos-install-tools nixos-generate-config --root "$TARGET_ROOT"
confirm_overwrite "$REPO_ROOT/hosts/loca/hardware-configuration.nix"
cp "$TARGET_ROOT/etc/nixos/hardware-configuration.nix" "$REPO_ROOT/hosts/loca/hardware-configuration.nix"

luks_uuid="$(blkid -s UUID -o value "$root_part")"
confirm_overwrite "$REPO_ROOT/hosts/loca/luks.nix"
cat > "$REPO_ROOT/hosts/loca/luks.nix" <<EOF
{ ... }:
{
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/$luks_uuid";
    allowDiscards = true;
    preLVM = true;
  };
}
EOF

log "Seeding the sops-nix age key into the target system"
mkdir -p "$TARGET_ROOT/var/lib/sops-nix"
age_key_file="$TARGET_ROOT/var/lib/sops-nix/key.txt"
confirm_overwrite "$age_key_file"
command_or_nix_shell age age-keygen -o "$age_key_file"
chmod 600 "$age_key_file"
age_public_key="$(command_or_nix_shell age age-keygen -y "$age_key_file")"

primary_hash="$(hash_password "$primary_password")"
secondary_hash="$(hash_password "$secondary_password")"

tmp_secrets="$(mktemp)"
chmod 600 "$tmp_secrets"
cat > "$tmp_secrets" <<EOF
backup/restic/repository: $restic_repository
backup/restic/password: $restic_password
backup/restic/ssh-key: |
$(printf '%s\n' "$backup_ssh_key" | sed 's/^/  /')
users/esaiaswestberg/password-hash: "$primary_hash"
users/filippawestberg/password-hash: "$secondary_hash"
tailscale/auth-key: $tailscale_auth_key
vpn/proton/env: |
  PROTONVPN_WIREGUARD_PRIVATE_KEY=$proton_private_key
  PROTONVPN_WIREGUARD_PUBLIC_KEY=$proton_public_key
  PROTONVPN_WIREGUARD_ENDPOINT=$proton_endpoint
  PROTONVPN_IPV4_ADDRESS=$proton_ipv4_address
  PROTONVPN_DNS=$proton_dns
EOF

log "Encrypting secrets to $REPO_ROOT/secrets/loca.yaml"
confirm_overwrite "$REPO_ROOT/secrets/loca.yaml"
command_or_nix_shell sops sops --encrypt --age "$age_public_key" "$tmp_secrets" > "$REPO_ROOT/secrets/loca.yaml"
shred -u "$tmp_secrets"

log "Running NixOS install"
pushd "$REPO_ROOT" >/dev/null
nixos-install --flake ".#${HOST_NAME}"
popd >/dev/null

log ""
log "Bootstrap complete."
log "Next steps:"
log "  1. Review the generated hardware files in $REPO_ROOT/hosts/loca"
log "  2. Commit the changes"
log "  3. Reboot into the new system"
