#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

HOST_NAME="loca"
PRIMARY_USER="esaiaswestberg"
SECONDARY_USER="filippawestberg"
TARGET_ROOT="/mnt"
REPO_ROOT="${REPO_ROOT:-$(pwd)}"
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: scripts/bootstrap.sh [--dry-run]

Run from the NixOS installer as root. By default this script partitions the
target disk, writes the host files, creates encrypted secrets, and installs the
loca system.

Options:
  -n, --dry-run   Print the planned actions and exit before making changes.
  -h, --help      Show this help text.
EOF
}

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

require_command() {
  local command_name="$1"
  command -v "$command_name" >/dev/null 2>&1 || die "missing required command: $command_name"
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

section() {
  printf '\n== %s ==\n' "$1"
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

list_disks() {
  lsblk -dnpo NAME,SIZE,MODEL,TYPE | awk '$4 == "disk" {
    model = ""
    for (i = 3; i <= NF - 1; i++) {
      model = model $i
      if (i < NF - 1) model = model " "
    }
    print $1 "\t" $2 "\t" model
  }'
}

select_disk() {
  local disk_lines=()
  local line
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    disk_lines+=("$line")
  done < <(list_disks)

  [[ ${#disk_lines[@]} -gt 0 ]] || die "no disks found"

  if command -v fzf >/dev/null 2>&1; then
    local choice
    choice="$(printf '%s\n' "${disk_lines[@]}" | fzf --prompt="Select target disk> " --with-nth=1,2,3 --delimiter=$'\t')" || die "no disk selected"
    printf '%s' "${choice%%$'\t'*}"
    return 0
  fi

  log "Available disks:"
  local i=1
  local path size model
  for line in "${disk_lines[@]}"; do
    IFS=$'\t' read -r path size model <<<"$line"
    printf '  %d) %s  %s  %s\n' "$i" "$path" "$size" "${model:-unknown}"
    i=$((i + 1))
  done

  local selection
  while :; do
    selection="$(prompt "Select disk number")"
    [[ "$selection" =~ ^[0-9]+$ ]] || { log "Enter a number from the list."; continue; }
    (( selection >= 1 && selection < i )) || { log "Enter a number from the list."; continue; }
    IFS=$'\t' read -r path size model <<<"${disk_lines[$((selection - 1))]}"
    printf '%s' "$path"
    return 0
  done
}

show_bootstrap_summary() {
  local disk="$1"
  local boot_part="$2"
  local root_part="$3"
  section "Review"
  log "Target disk: $disk"
  log "Boot partition: $boot_part"
  log "Root partition: $root_part"
  log "Host: $HOST_NAME"
  log "Users: $PRIMARY_USER, $SECONDARY_USER"
  log "Secrets file: $REPO_ROOT/secrets/loca.yaml"
  log "Host files:"
  log "  - $REPO_ROOT/hosts/loca/hardware-configuration.nix"
  log "  - $REPO_ROOT/hosts/loca/luks.nix"
}

collect_secret_values() {
  section "Local accounts"
  luks_passphrase="$(prompt_secret_confirm "LUKS passphrase")"
  primary_password="$(prompt_secret_confirm "Password for $PRIMARY_USER")"
  secondary_password="$(prompt_secret_confirm "Password for $SECONDARY_USER")"

  section "Backup"
  restic_repository="$(prompt "Restic repository URL" "sftp:user@backup.example.com:/srv/restic/loca")"
  restic_password="$(prompt_secret_confirm "Restic repository password")"
  backup_ssh_key="$(prompt_multiline "Paste the backup SSH private key")"

  section "VPN"
  tailscale_auth_key="$(prompt_secret_confirm "Tailscale auth key")"
  proton_private_key="$(prompt_secret_confirm "ProtonVPN WireGuard private key")"
  proton_public_key="$(prompt_secret_confirm "ProtonVPN WireGuard public key")"
  proton_endpoint="$(prompt "ProtonVPN WireGuard endpoint")"
  proton_ipv4_address="$(prompt "ProtonVPN IPv4 address")"
  proton_dns="$(prompt "ProtonVPN DNS server")"
}

preflight_checks() {
  require_root
  require_repo_root
  [[ -d "$REPO_ROOT/hosts/loca" ]] || die "missing host directory: $REPO_ROOT/hosts/loca"
  [[ -d "$REPO_ROOT/secrets" ]] || die "missing secrets directory: $REPO_ROOT/secrets"
  [[ -w "$REPO_ROOT/hosts/loca" ]] || die "host directory is not writable: $REPO_ROOT/hosts/loca"
  [[ -w "$REPO_ROOT/secrets" ]] || die "secrets directory is not writable: $REPO_ROOT/secrets"
  require_command mountpoint
  if mountpoint -q "$TARGET_ROOT"; then
    die "$TARGET_ROOT is already mounted; unmount it before running the bootstrap"
  fi
  require_command lsblk
  require_command nix
  require_command sgdisk
  require_command parted
  require_command partprobe
  require_command udevadm
  require_command mkfs.fat
  require_command mkfs.ext4
  require_command cryptsetup
  require_command mount
  require_command umount
  require_command blkid
  require_command shred
}

print_dry_run() {
  log "Dry run only. Planned actions:"
  log "  - verify the target disk and repo paths are ready"
  log "  - partition the disk as GPT with EFI + LUKS root"
  log "  - generate host hardware and LUKS files"
  log "  - seed /var/lib/sops-nix/key.txt into the target system"
  log "  - prompt for user passwords and secret values"
  log "  - hash the passwords and encrypt secrets/loca.yaml"
  log "  - install the NixOS configuration for loca"
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

for arg in "$@"; do
  case "$arg" in
    -n|--dry-run)
      DRY_RUN=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $arg"
      ;;
  esac
done

preflight_checks

log "Repository root: $REPO_ROOT"
log "Target host: $HOST_NAME"
log "Primary user: $PRIMARY_USER"
log "Secondary user: $SECONDARY_USER"

if (( DRY_RUN )); then
  print_dry_run
  exit 0
fi

section "Disk selection"
disk="$(select_disk)"
[[ -b "$disk" ]] || die "not a block device: $disk"

log ""
log "Current block devices:"
lsblk -dpno NAME,SIZE,MODEL "$disk" || true

collect_secret_values

boot_part="$(partition_path "$disk" 1)"
root_part="$(partition_path "$disk" 2)"

show_bootstrap_summary "$disk" "$boot_part" "$root_part"
confirm "This will erase $disk and create a new GPT + LUKS layout"

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
command_or_nix_shell nixos-install-tools nixos-install --flake ".#${HOST_NAME}"
popd >/dev/null

log ""
log "Bootstrap complete."
log "Next steps:"
log "  1. Review the generated hardware files in $REPO_ROOT/hosts/loca"
log "  2. Commit the changes"
log "  3. Reboot into the new system"
