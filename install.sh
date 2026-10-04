#!/usr/bin/env bash
set -Eeuo pipefail

UPSTREAM_REPO="https://github.com/xsqu1znt/PdaNetClientCLI-Linux.git"
UPSTREAM_COMMIT="f20ae0e679f26d1703f6a99ffc1978fc7c7dd84f"
BASE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="$HOME/.local/share/pdanet-l4t"
UPSTREAM_DIR="$STATE_DIR/upstream/PdaNetClientCLI-Linux"
PACKAGE_MANIFEST="$STATE_DIR/installed-packages.txt"
PACKAGE_PREVIOUS="$STATE_DIR/installed-packages.previous"
readonly -a REMOVABLE_PACKAGE_CANDIDATES=(adb dnscrypt-proxy redsocks python3-pyqt5 kdialog nftables openvpn libsecret-tools)
readonly -a REQUIRED_APT_PACKAGES=(
    adb bash coreutils curl dnscrypt-proxy gawk git grep iproute2 iptables
    kdialog libc-bin libsecret-tools nftables openvpn policykit-1 python3 python3-pyqt5 redsocks systemd util-linux
)

info() { printf '==> %s\n' "$*"; }
ok() { printf '  OK  %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

[[ $EUID -ne 0 ]] || die "Run this installer as your normal desktop user, not with sudo."
command -v apt-get >/dev/null 2>&1 || die "This release currently targets Debian/Ubuntu/Switchroot systems using APT."
command -v sudo >/dev/null 2>&1 || die "sudo is required."

info "Preparing package ownership tracking"
mkdir -p "$STATE_DIR/upstream"
if [[ -f "$PACKAGE_MANIFEST" ]]; then
    cp -f "$PACKAGE_MANIFEST" "$PACKAGE_PREVIOUS"
else
    : > "$PACKAGE_PREVIOUS"
fi

info "Checking required PdaNet L4T packages"
declare -a missing_required_packages=()
for package in "${REQUIRED_APT_PACKAGES[@]}"; do
    if ! dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -qx 'install ok installed'; then
        missing_required_packages+=("$package")
    fi
done

package_new="$(mktemp)"
: > "$package_new"

if (( ${#missing_required_packages[@]} > 0 )); then
    info "Installing missing PdaNet L4T packages: ${missing_required_packages[*]}"
    sudo apt-get update
    apt_log="$(mktemp)"
    sudo env LC_ALL=C apt-get install -y "${missing_required_packages[@]}" 2>&1 | tee "$apt_log"

    info "Recording only packages newly installed by this APT transaction"
    while IFS= read -r package; do
        package="${package%%:*}"
        case "$package" in
            adb|dnscrypt-proxy|redsocks|python3-pyqt5|kdialog|nftables|openvpn|libsecret-tools)
                printf '%s\n' "$package" >> "$package_new"
                ;;
        esac
    done < <(
        awk '
            $0 == "The following NEW packages will be installed:" { capture=1; next }
            capture && ($0 ~ /^The following / || $0 ~ /^[0-9]+ upgraded,/) { capture=0 }
            capture { for (i=1; i<=NF; i++) print $i }
        ' "$apt_log"
    )
    rm -f "$apt_log"
else
    ok "All required APT packages are already installed; no package state changed."
fi

cat "$PACKAGE_PREVIOUS" "$package_new" | sed '/^[[:space:]]*$/d' | LC_ALL=C sort -u > "$PACKAGE_MANIFEST"
rm -f "$package_new" "$PACKAGE_PREVIOUS"

if [[ -d "$UPSTREAM_DIR/.git" ]]; then
    info "Refreshing xsqu1znt/PdaNetClientCLI-Linux"
    git -C "$UPSTREAM_DIR" fetch --all --tags
else
    info "Cloning xsqu1znt/PdaNetClientCLI-Linux"
    git clone "$UPSTREAM_REPO" "$UPSTREAM_DIR"
fi

git -C "$UPSTREAM_DIR" checkout --detach "$UPSTREAM_COMMIT"
actual_commit="$(git -C "$UPSTREAM_DIR" rev-parse HEAD)"
[[ "$actual_commit" == "$UPSTREAM_COMMIT" ]] || die "Upstream commit verification failed."
ok "Pinned upstream commit: $actual_commit"

info "Running the upstream installer"
bash "$UPSTREAM_DIR/install.sh" --skip-packages

redsocks_bin="$(command -v redsocks || true)"
dnscrypt_bin="$(command -v dnscrypt-proxy || true)"
[[ -n "$redsocks_bin" ]] || die "redsocks executable not found after upstream installation."
[[ -n "$dnscrypt_bin" ]] || die "dnscrypt-proxy executable not found after upstream installation."

info "Applying L4T/Noble service-path compatibility"
sudo sed -Ei "s|^ExecStart=.*redsocks.*|ExecStart=${redsocks_bin} -c /etc/redsocks-pdanet.conf|" /etc/systemd/system/pdanet-redsocks.service
sudo sed -Ei "s|^ExecStart=.*dnscrypt-proxy.*|ExecStart=${dnscrypt_bin} -config /etc/dnscrypt-proxy-pdanet.toml -syslog|" /etc/systemd/system/pdanet-dnscrypt.service
sudo systemctl daemon-reload

info "Applying dnscrypt-proxy compatibility"
sudo sed -i '/^[[:space:]]*odoh_servers[[:space:]]*=/d' /etc/dnscrypt-proxy-pdanet.toml
sudo sed -i '/^[[:space:]]*http3[[:space:]]*=/d' /etc/dnscrypt-proxy-pdanet.toml

info "Checking iptables-legacy NAT support"
if command -v iptables-legacy >/dev/null 2>&1; then
    IPT="$(command -v iptables-legacy)"
elif iptables -V 2>/dev/null | grep -qi legacy; then
    IPT="$(command -v iptables)"
else
    die "iptables-legacy is unavailable. This L4T compatibility release cannot safely install."
fi
sudo "$IPT" -t nat -N PDANET_INSTALL_TEST 2>/dev/null || true
sudo "$IPT" -t nat -F PDANET_INSTALL_TEST
sudo "$IPT" -t nat -A PDANET_INSTALL_TEST -p tcp -j REDIRECT --to-ports 12345
sudo "$IPT" -t nat -F PDANET_INSTALL_TEST
sudo "$IPT" -t nat -X PDANET_INSTALL_TEST
ok "iptables-legacy REDIRECT is available."

info "Installing PdaNet L4T wrapper"
sudo install -m 0755 "$BASE_DIR/src/pdanet-l4t" /usr/local/sbin/pdanet-l4t
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications" "$HOME/.config/autostart"
install -m 0755 "$BASE_DIR/src/pdanet-l4t-tray" "$HOME/.local/bin/pdanet-l4t-tray"
install -m 0755 "$BASE_DIR/src/pdanet-l4t-launch" "$HOME/.local/bin/pdanet-l4t-launch"
install -m 0755 "$BASE_DIR/uninstall.sh" "$HOME/.local/bin/pdanet-l4t-uninstall"

read -r -p "PdaNet proxy IP [192.168.49.1]: " proxy_ip
proxy_ip="${proxy_ip:-192.168.49.1}"
read -r -p "PdaNet proxy port [8000]: " proxy_port
proxy_port="${proxy_port:-8000}"
sudo /usr/local/sbin/pdanet-l4t set-proxy "$proxy_ip" "$proxy_port"

cat > "$HOME/.local/share/applications/pdanet-l4t.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=PdaNet L4T
Comment=PdaNet WiFi Direct compatibility utility for legacy L4T
Icon=network-vpn
Exec=$HOME/.local/bin/pdanet-l4t-launch
Terminal=false
Categories=Network;
DESKTOP
chmod +x "$HOME/.local/share/applications/pdanet-l4t.desktop"

cat > "$HOME/.config/autostart/pdanet-l4t.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=PdaNet L4T
Comment=Start PdaNet L4T tray utility
Icon=network-vpn
Exec=$HOME/.local/bin/pdanet-l4t-launch
Terminal=false
X-GNOME-Autostart-enabled=true
DESKTOP

rm -f "$HOME/.local/share/applications/pdanet-l4t-v2.desktop"
rm -f "$HOME/.local/share/applications/pdanet-l4t-v2-off.desktop"
rm -f "$HOME/.local/share/applications/pdanet-l4t-on.desktop"
rm -f "$HOME/.local/share/applications/pdanet-l4t-off.desktop"

if command -v kbuildsycoca5 >/dev/null 2>&1; then
    kbuildsycoca5 >/dev/null 2>&1 || true
fi

info "Verifying installed files"
bash -n /usr/local/sbin/pdanet-l4t
python3 -m py_compile "$HOME/.local/bin/pdanet-l4t-tray"
bash -n "$HOME/.local/bin/pdanet-l4t-launch"
bash -n "$HOME/.local/bin/pdanet-l4t-uninstall"
ok "Installation checks passed."

printf '\nInstallation complete.\n'
printf '1. On Android: PdaNet+ -> WiFi Direct Hotspot -> ON\n'
printf '2. Join that DIRECT-...-PdaNet Wi-Fi network in Linux.\n'
printf '3. Open PdaNet L4T from the application menu or tray and choose Connect.\n'
printf '4. Optional Full Tunnel mode can use a trusted OpenVPN TCP .ovpn profile from the tray.\n'
printf '5. Uninstall later with: pdanet-l4t-uninstall\n'
printf '\nUpstream base: xsqu1znt/PdaNetClientCLI-Linux @ %s\n' "$UPSTREAM_COMMIT"
