#!/usr/bin/env bash
set -Eeuo pipefail

[[ $EUID -ne 0 ]] || { echo "Run as your normal desktop user, not with sudo." >&2; exit 1; }

pkill -f "$HOME/.local/bin/pdanet-l4t-tray" 2>/dev/null || true
if [[ -x /usr/local/sbin/pdanet-l4t ]]; then
    sudo /usr/local/sbin/pdanet-l4t off 2>/dev/null || true
fi

sudo rm -f /usr/local/sbin/pdanet-l4t
rm -f "$HOME/.local/bin/pdanet-l4t-tray"
rm -f "$HOME/.local/bin/pdanet-l4t-launch"
rm -f "$HOME/.local/share/applications/pdanet-l4t.desktop"
rm -f "$HOME/.config/autostart/pdanet-l4t.desktop"

if [[ "${1:-}" == "--purge-config" ]]; then
    sudo rm -f /etc/pdanet-l4t.conf
fi

if command -v kbuildsycoca5 >/dev/null 2>&1; then
    kbuildsycoca5 >/dev/null 2>&1 || true
fi

cat <<'MSG'
PdaNet L4T wrapper removed.
The upstream xsqu1znt PdaNetClientCLI-Linux installation was intentionally left installed.
Use --purge-config if you also want /etc/pdanet-l4t.conf removed.
MSG
