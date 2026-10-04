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

## 7. Collect diagnostics

Run:

```bash
bash diagnose.sh
```

Useful issue-report fields include kernel, architecture, distro, upstream commit, `iptables-legacy` availability, redsocks/dnscrypt versions, service status and whether ports `12345` and `5300` are listening.
