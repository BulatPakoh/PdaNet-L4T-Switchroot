#!/usr/bin/env bash
set -Eeuo pipefail

[[ $EUID -ne 0 ]] || { echo "Run as your normal desktop user, not with sudo." >&2; exit 1; }

STATE_DIR="$HOME/.local/share/pdanet-l4t"
PACKAGE_MANIFEST="$STATE_DIR/installed-packages.txt"
INSTALLED_UNINSTALLER="$HOME/.local/bin/pdanet-l4t-uninstall"
REMOVE_PACKAGES=0
ASSUME_YES=0

usage() {
    cat <<'EOF'
PdaNet L4T Uninstaller

Normal uninstall:
  pdanet-l4t-uninstall

  Removes PdaNet L4T and the PdaNet/xsqu1znt files installed by this project.
  Keeps Ubuntu packages and keeps your GitHub source folder.

Full cleanup:
  pdanet-l4t-uninstall --remove-packages

  Does the normal uninstall, then also removes only the PdaNet-related
  packages that this installer recorded as newly installed.
  You will see the package list and be asked before anything is removed.
  If APT says other unrecorded packages would also be removed, it stops.

Options:
  --remove-packages   Remove installer-added PdaNet dependency packages.
  -y, --yes           Skip only the package-removal confirmation.
  -h, --help          Show this help.
EOF
}

while (( $# > 0 )); do
    case "$1" in
        --remove-packages) REMOVE_PACKAGES=1 ;;
        -y|--yes) ASSUME_YES=1 ;;
        --purge-config)
            echo "NOTE: --purge-config is no longer needed; full PdaNet-specific cleanup is now the default."
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            usage >&2
            echo "ERROR: Unknown option: $1" >&2
            exit 2
            ;;
    esac
    shift
done

declare -a owned_packages=()
if (( REMOVE_PACKAGES == 1 )) && [[ -s "$PACKAGE_MANIFEST" ]]; then
    while IFS= read -r package; do
        [[ -n "$package" ]] || continue
        if dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -qx 'install ok installed'; then
            owned_packages+=("$package")
        fi
    done < "$PACKAGE_MANIFEST"
fi

if (( REMOVE_PACKAGES == 1 )) && (( ${#owned_packages[@]} > 0 )); then
    mapfile -t proposed_removals < <(
        apt-get -s purge "${owned_packages[@]}" 2>/dev/null             | awk '/^Remv / { print $2 }'             | LC_ALL=C sort -u
    )
    mapfile -t allowed_removals < <(printf '%s\n' "${owned_packages[@]}" | LC_ALL=C sort -u)
    mapfile -t extra_removals < <(
        comm -13             <(printf '%s\n' "${allowed_removals[@]}")             <(printf '%s\n' "${proposed_removals[@]}")
    )

    if (( ${#extra_removals[@]} > 0 )); then
        echo "ERROR: Package removal was stopped because APT also wants to remove packages"
        echo "that were not recorded as installed by PdaNet L4T:"
        printf '  %s\n' "${extra_removals[@]}"
        echo
        echo "Run the normal uninstaller instead, or review your package dependencies manually."
        exit 1
    fi

    echo "Safe removable packages recorded as added by PdaNet L4T:"
    printf '  %s\n' "${owned_packages[@]}"
    echo
    if (( ASSUME_YES == 0 )); then
        read -r -p "Remove these packages after PdaNet cleanup? [y/N]: " answer
        case "$answer" in
            y|Y|yes|YES) ;;
            *)
                echo "Cancelled before making changes."
                exit 0
                ;;
        esac
    fi
elif (( REMOVE_PACKAGES == 1 )); then
    echo "No currently installed packages are recorded as installer-owned."
    echo "PdaNet-specific files will still be removed."
fi

echo "==> Stopping PdaNet"
pkill -f "$HOME/.local/bin/pdanet-l4t-tray" 2>/dev/null || true

if [[ -x /usr/local/sbin/pdanet-l4t ]]; then
    sudo /usr/local/sbin/pdanet-l4t off 2>/dev/null || true
fi
if [[ -x "$HOME/.local/bin/pdanet" ]]; then
    sudo "$HOME/.local/bin/pdanet" usb off 2>/dev/null || true
    sudo "$HOME/.local/bin/pdanet" off 2>/dev/null || true
fi

sudo systemctl stop pdanet-redsocks pdanet-dnscrypt pdanet-usb-dnscrypt 2>/dev/null || true
sudo systemctl disable pdanet-redsocks pdanet-dnscrypt pdanet-usb-dnscrypt 2>/dev/null || true

echo "==> Removing PdaNet routing state"
if command -v iptables-legacy >/dev/null 2>&1; then
    IPT="$(command -v iptables-legacy)"
elif command -v iptables >/dev/null 2>&1 && iptables -V 2>/dev/null | grep -qi legacy; then
    IPT="$(command -v iptables)"
else
    IPT=""
fi

if [[ -n "$IPT" ]]; then
    while sudo "$IPT" -t nat -C OUTPUT -j PDANET 2>/dev/null; do
        sudo "$IPT" -t nat -D OUTPUT -j PDANET 2>/dev/null || break
    done
    sudo "$IPT" -t nat -F PDANET 2>/dev/null || true
    sudo "$IPT" -t nat -X PDANET 2>/dev/null || true
    sudo "$IPT" -t nat -F PDANET_INSTALL_TEST 2>/dev/null || true
    sudo "$IPT" -t nat -X PDANET_INSTALL_TEST 2>/dev/null || true
fi

if command -v nft >/dev/null 2>&1; then
    sudo nft delete table inet pdanet 2>/dev/null || true
fi

sudo rm -rf /run/pdanet-l4t.connected /run/pdanet-tproxy /run/pdanet-usb
sudo rm -f /run/pdanet-usb-helper.log

echo "==> Removing PdaNet L4T and upstream xsqu1znt files"
sudo rm -f /usr/local/sbin/pdanet-l4t /usr/local/sbin/pdanet-l4t-v2
sudo rm -f     /etc/pdanet-l4t.conf     /etc/nftables-pdanet.nft     /etc/redsocks-pdanet.conf     /etc/dnscrypt-proxy-pdanet.toml     /etc/dnscrypt-proxy-pdanet-usb.toml     /etc/systemd/system/pdanet-redsocks.service     /etc/systemd/system/pdanet-dnscrypt.service     /etc/systemd/system/pdanet-usb-dnscrypt.service
sudo systemctl daemon-reload

rm -f     "$HOME/.local/bin/pdanet"     "$HOME/.local/libexec/pdanet-usb-helper"     "$HOME/.local/bin/pdanet-l4t-tray"     "$HOME/.local/bin/pdanet-l4t-launch"     "$HOME/.local/bin/pdanet-l4t-gui"     "$HOME/.local/share/applications/pdanet-l4t.desktop"     "$HOME/.local/share/applications/pdanet-l4t-v2.desktop"     "$HOME/.local/share/applications/pdanet-l4t-v2-off.desktop"     "$HOME/.local/share/applications/pdanet-l4t-on.desktop"     "$HOME/.local/share/applications/pdanet-l4t-off.desktop"     "$HOME/.config/autostart/pdanet-l4t.desktop"     "$HOME/.cache/pdanet-l4t-tray.lock"

rm -f "$HOME/.local/bin/__pycache__"/pdanet-l4t-tray*.pyc 2>/dev/null || true

if (( REMOVE_PACKAGES == 1 )) && (( ${#owned_packages[@]} > 0 )); then
    echo "==> Removing packages added by PdaNet L4T"
    sudo apt-get purge -y "${owned_packages[@]}"
fi

rm -rf "$STATE_DIR"

if command -v kbuildsycoca5 >/dev/null 2>&1; then
    kbuildsycoca5 >/dev/null 2>&1 || true
fi

# Remove the installed rescue command too. If this script is being run from the
# GitHub checkout, the checkout's uninstall.sh is intentionally left untouched.
rm -f "$INSTALLED_UNINSTALLER"

echo
echo "PdaNet L4T removal complete."
echo "Removed: wrapper, tray, autostart, xsqu1znt user files, PdaNet configs/services and routing state."
if (( REMOVE_PACKAGES == 1 )); then
    if (( ${#owned_packages[@]} > 0 )); then
        echo "Also removed the safe dependency packages recorded as added by PdaNet L4T."
    else
        echo "No installer-owned packages needed removal."
    fi
else
    echo "Shared Ubuntu packages were kept."
fi

if [[ -d "$HOME/PdaNet-L4T-Switchroot/.git" ]]; then
    echo
    echo "The GitHub source checkout was kept:"
    echo "  $HOME/PdaNet-L4T-Switchroot"
    echo "To remove it too, leave that directory first, then delete it manually."
fi
