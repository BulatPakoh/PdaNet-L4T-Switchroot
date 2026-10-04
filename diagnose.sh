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
for cmd in iptables iptables-legacy redsocks dnscrypt-proxy openvpn secret-tool curl pkexec python3; do
    printf '%-18s %s\n' "$cmd" "$(command -v "$cmd" 2>/dev/null || echo MISSING)"
done

echo
echo "--- Versions ---"
iptables -V 2>/dev/null || true
iptables-legacy -V 2>/dev/null || true
redsocks -v 2>&1 | head -n 1 || true
dnscrypt-proxy -version 2>&1 | head -n 2 || true
openvpn --version 2>/dev/null | head -n 1 || true
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
echo "--- Full Tunnel state ---"
if [[ -r /run/pdanet-l4t-full-tunnel.connected ]]; then
    cat /run/pdanet-l4t-full-tunnel.connected
else
    echo "offline/no Full Tunnel state file"
fi

if [[ -r /run/pdanet-l4t-openvpn.pid ]]; then
    full_tunnel_pid="$(cat /run/pdanet-l4t-openvpn.pid 2>/dev/null || true)"
    if [[ "$full_tunnel_pid" =~ ^[0-9]+$ ]]; then
        ps -p "$full_tunnel_pid" -o pid=,comm=,etime= 2>/dev/null || echo "recorded OpenVPN PID is not running"
    else
        echo "invalid OpenVPN PID file"
    fi
else
    echo "no OpenVPN PID file"
fi

echo
echo "--- tun0 ---"
if ip link show tun0 >/dev/null 2>&1; then
    ip -brief addr show tun0 2>/dev/null || true
    ip route show dev tun0 2>/dev/null | head -n 20 || true
else
    echo "tun0 not present"
fi

echo
echo "--- Desktop keyring integration ---"
if command -v secret-tool >/dev/null 2>&1; then
    echo "secret-tool: available"
else
    echo "secret-tool: missing"
fi
if command -v busctl >/dev/null 2>&1 && busctl --user --no-pager list 2>/dev/null | grep -q 'org.freedesktop.secrets'; then
    echo "Secret Service: available"
else
    echo "Secret Service: unavailable/not visible"
fi
if command -v busctl >/dev/null 2>&1 && busctl --user --no-pager list 2>/dev/null | grep -q 'org.kde.kwalletd'; then
    echo "KWallet service: visible"
else
    echo "KWallet service: unavailable/not visible"
fi

echo
echo "--- Full Tunnel preferences (no credentials) ---"
PREFS="$HOME/.config/pdanet-l4t/full-tunnel.ini"
if [[ -r "$PREFS" ]]; then
    awk -F= '
        /^[[:space:]]*profile[[:space:]]*=/ {
            value=$2
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
            print "saved_profile: " (length(value) ? "yes" : "no")
        }
        /^[[:space:]]*auto_connect[[:space:]]*=/ {
            value=$2
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
            print "auto_connect: " value
        }
    ' "$PREFS"
else
    echo "no saved Full Tunnel preferences"
fi

echo
echo "--- Services ---"
for service in pdanet-redsocks pdanet-dnscrypt; do
    printf '%-22s ' "$service"
    systemctl is-active "$service" 2>/dev/null || true
    systemctl show "$service" --no-pager \
        -p LoadState -p ActiveState -p SubState -p MainPID 2>/dev/null \
        | sed 's/^/  /' || true
done

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
