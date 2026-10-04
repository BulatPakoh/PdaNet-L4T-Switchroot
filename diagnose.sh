#!/usr/bin/env bash
set -u

echo "=== PdaNet L4T diagnostics ==="
echo "Date: $(date -Is 2>/dev/null || date)"
echo "Kernel: $(uname -r)"
echo "Machine: $(uname -m)"
echo "Architecture: $(dpkg --print-architecture 2>/dev/null || echo unknown)"
if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    echo "OS: ${PRETTY_NAME:-unknown}"
else
    echo "OS: unknown"
fi

echo
echo "--- Commands ---"
for cmd in iptables iptables-legacy redsocks dnscrypt-proxy openvpn curl pkexec python3; do
    printf '%-18s %s\n' "$cmd" "$(command -v "$cmd" 2>/dev/null || echo MISSING)"
done

echo
echo "--- Versions ---"
iptables -V 2>/dev/null || true
iptables-legacy -V 2>/dev/null || true
redsocks -v 2>&1 | head -n 1 || true
dnscrypt-proxy -version 2>&1 | head -n 2 || true
python3 --version 2>&1 || true

echo
echo "--- Wrapper config ---"
if [[ -r /etc/pdanet-l4t.conf ]]; then
    cat /etc/pdanet-l4t.conf
else
    echo "missing"
fi

echo
echo "--- State ---"
if [[ -r /run/pdanet-l4t.connected ]]; then
    cat /run/pdanet-l4t.connected
else
    echo "disconnected/no state file"
fi

echo
echo "--- Services ---"
systemctl --no-pager --full status pdanet-redsocks pdanet-dnscrypt 2>&1 | tail -n 40 || true

echo
echo "--- Listening ports ---"
ss -lntup 2>/dev/null | grep -E ':(12345|5300)' || echo "ports 12345/5300 not listening"

echo
echo "--- L4T NAT capability ---"
if modprobe -n nft_chain_nat >/dev/null 2>&1; then
    echo "nft_chain_nat: module known to this kernel"
else
    echo "nft_chain_nat: unavailable/not known"
fi
if command -v iptables-legacy >/dev/null 2>&1; then
    echo "iptables-legacy: available"
else
    echo "iptables-legacy: missing"
fi

echo
echo "--- Upstream checkout ---"
UP="$HOME/.local/share/pdanet-l4t/upstream/PdaNetClientCLI-Linux"
if [[ -d "$UP/.git" ]]; then
    git -C "$UP" rev-parse HEAD 2>/dev/null || true
    git -C "$UP" log -1 --format='%h | %cd | %s' 2>/dev/null || true
else
    echo "upstream checkout not found at $UP"
fi
