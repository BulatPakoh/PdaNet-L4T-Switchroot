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

Expected for Wi-Fi Direct mode. The upstream client documents Wi-Fi mode as TCP + DNS through the Android HTTP proxy, without arbitrary ICMP/UDP. Test with HTTPS instead:

```bash
curl -I https://google.com
sudo apt update
```

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

## 11. Collect diagnostics

Run:

```bash
bash diagnose.sh
```

Useful issue-report fields include kernel, architecture, distro, upstream commit, `iptables-legacy` availability, redsocks/dnscrypt versions, service status and whether ports `12345` and `5300` are listening.
