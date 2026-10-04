# Troubleshooting notes from the tested Switchroot session

These are not hypothetical errors. They were encountered on the tested Nintendo Switch OLED / Switchroot Noble system while adapting xsqu1znt/PdaNetClientCLI-Linux.

## 1. Upstream Wi-Fi activation rolls back at nftables

Symptoms included upstream activation failing after the proxy services had started. The tested kernel was:

```text
4.9.140-l4t
```

Testing showed:

```text
modprobe: FATAL: Module nft_chain_nat not found in directory /lib/modules/4.9.140-l4t
```

But legacy NAT was available:

```bash
sudo iptables-legacy -t nat -L OUTPUT -n
```

and a test `REDIRECT` rule succeeded. PdaNet L4T therefore uses `iptables-legacy` instead of the upstream nftables Wi-Fi routing path.

## 2. redsocks: `bind: Address already in use`

Observed log:

```text
redsocks_init_instance(...) bind: Address already in use
```

The default `redsocks` service could already be occupying port `12345`. The wrapper stops the generic service before starting `pdanet-redsocks`:

```text
systemctl stop redsocks
```

It does not globally disable or remove redsocks.

## 3. dnscrypt-proxy 2.0.45 rejects newer config keys

Observed errors:

```text
Unsupported key in configuration file: [odoh_servers]
Unsupported key in configuration file: [http3]
```

The tested Noble package reported dnscrypt-proxy `2.0.45`. The wrapper removes the `odoh_servers` and `http3` assignments from the PdaNet-specific DNS config. It also updates `http_proxy` when the user changes PdaNet proxy IP/port.

## 4. `/usr/bin` vs `/usr/sbin` service paths

The tested upstream commit defines systemd `ExecStart` paths using `/usr/bin/redsocks` and `/usr/bin/dnscrypt-proxy`. Package layouts can place these programs elsewhere. The installer uses `command -v` and rewrites the two PdaNet systemd units to the executable paths actually installed on the target system.

## 5. Browser/apt works but `ping` does not

Expected for **standard WiFi Direct mode**. The tested path carries TCP + DNS through the Android HTTP proxy and does not provide arbitrary ICMP/raw UDP. Test standard mode with HTTPS instead:

```bash
curl -I https://google.com
sudo apt update
```

The optional OpenVPN TCP Full Tunnel can carry UDP-capable application traffic through `tun0`, but that does not turn the underlying PdaNet WiFi Direct proxy into a raw-UDP/ICMP link.

## 6. Tray says disconnected after a successful connection

Early development builds tried to inspect iptables rules from the unprivileged GUI. That produces a false disconnected state because reading legacy NAT rules requires elevated privileges. The final tray uses a root-created state marker plus unprivileged service/port checks instead.

## 7. Cannot reach the PdaNet proxy

If Connect stops at:

```text
Cannot reach 192.168.49.1:8000
```

first confirm that Linux is connected to the phone's `DIRECT-...-PdaNet` Wi-Fi network and that PdaNet+ still shows the same proxy IP and port.

The proxy can be tested directly without enabling PdaNet L4T:

```bash
curl -I --proxy http://192.168.49.1:8000 https://example.com
```

If the phone displays a different proxy address or port, update it from the tray with **Change Proxy** before connecting again.

## 8. `iptables` reports `(nf_tables)` or warns about legacy tables

On the tested system:

```text
iptables v1.8.10 (nf_tables)
```

while PdaNet L4T deliberately uses `iptables-legacy`.

These are separate firewall backends/rulesets. A warning such as:

```text
# Warning: iptables-legacy tables present, use iptables-legacy to see them
```

does not by itself mean PdaNet L4T is broken.

When inspecting PdaNet L4T's `PDANET` NAT chain on this system, use the legacy backend explicitly:

```bash
sudo iptables-legacy -t nat -L -n
```

Do not flush entire nftables or legacy tables as a troubleshooting shortcut; unrelated system firewall rules may exist.

## 9. HTTPS validation fails and the connection rolls back

The backend performs an HTTPS request after starting the proxy services and applying the routing rules.

If that validation fails, PdaNet L4T intentionally removes its routing rules, stops its PdaNet-specific proxy services and leaves the state as disconnected rather than reporting a false success.

Check the PdaNet Wi-Fi connection, proxy address, and service state, then run:

```bash
bash diagnose.sh
```

The rollback is a safety behavior, not a second connection mode.

## 10. Tray does not appear immediately after installation

The installer creates the application-menu entry and login autostart entry, but it does not launch the tray in the same desktop session automatically.

After installation, either open **PdaNet L4T** once from the application menu/search or log out/reboot. The tray should start automatically on the next login.

## 11. Full Tunnel button is disabled

**Connect Full Tunnel** is only enabled after standard PdaNet L4T mode is online.

Use the normal **Connect** action first. After standard mode reports connected, the Full Tunnel action becomes available.

If auto-connect is enabled and a saved profile plus keyring credential are available, the normal **Connect** action starts both layers automatically.

## 12. Full Tunnel reports authentication failure

A provider may use separate OpenVPN credentials instead of the password used to sign in to its website or application.

Use the OpenVPN credentials documented by the VPN provider. Do not post those credentials in an issue.

PdaNet L4T requires a trusted OpenVPN **TCP** profile. Profiles using only UDP transport are rejected by the Full Tunnel backend.

When a TCP profile contains a port-443 remote, the generated runtime profile prefers that remote because it was the confirmed working path on the tested setup. If no port-443 remote exists, the profile's existing TCP remotes are preserved.

## 13. Discord voice shows `Checking Route` / `No Route`

This was reproduced in standard PdaNet L4T mode on the tested Switchroot system.

The tested A/B behavior was:

```text
Standard PdaNet mode        Discord voice: No Route
Normal phone hotspot        Discord voice: PASS
OpenVPN TCP Full Tunnel     Discord voice: PASS
Stop Full Tunnel            Discord voice: No Route
Reconnect Full Tunnel       Discord voice: PASS
```

This does not prove that every voice/game application will work through Full Tunnel. It confirms the tested Discord voice workload through `tun0`.

## 14. Why does Ubuntu ask for a password?

Routing and OpenVPN/TUN setup require privileged operations, so PdaNet L4T uses PolicyKit/`pkexec` instead of running the entire tray as root.

With a saved Full Tunnel profile, saved keyring credential and **Auto-connect Full Tunnel** enabled, the main **Connect** action performs standard PdaNet + Full Tunnel startup in one privileged backend transaction. The final tested flow required one PolicyKit password prompt.

Manually choosing **Connect Full Tunnel** later is a separate privileged action and can therefore request PolicyKit authorization again.

A GPG/KWallet unlock prompt after login/reboot is separate from PolicyKit. It belongs to the desktop wallet/keyring configuration and may appear before saved Wi-Fi or Full Tunnel secrets can be read.

## 15. Saved Full Tunnel profile is missing

If the saved `.ovpn` file was moved, renamed or deleted, auto-connect is skipped.

Use **Change Full Tunnel Profile...** and select a trusted replacement profile. The replacement is tested before it becomes the saved profile.

## 16. Auto-connect is enabled but Full Tunnel does not start

Check these conditions:

- standard PdaNet L4T is connected;
- the saved `.ovpn` file still exists;
- the saved profile uses OpenVPN TCP;
- the desktop Secret Service/keyring is available and unlocked;
- the provider credentials are still valid.

The tray intentionally does not auto-connect standard PdaNet immediately at desktop login. Auto-connect applies to the Full Tunnel **after standard PdaNet is connected**.

## 17. OpenVPN log and runtime files

The backend writes the current OpenVPN log to:

```text
/run/pdanet-l4t-openvpn.log
```

Runtime profile/auth files use mode `0600`. The temporary authentication file is removed after the OpenVPN startup result is known.

Review logs before posting them publicly. Do not post provider credentials, private keys, keyring contents or private material embedded in a provider profile.

## 18. Collect diagnostics

Run:

```bash
bash diagnose.sh
```

Useful issue-report fields include kernel, architecture, distro, upstream commit, `iptables-legacy` availability, redsocks/dnscrypt/OpenVPN versions, standard connection state, Full Tunnel state, `tun0` state, Secret Service availability and whether ports `12345` and `5300` are listening.

The diagnostic script is designed not to print saved OpenVPN credentials.
