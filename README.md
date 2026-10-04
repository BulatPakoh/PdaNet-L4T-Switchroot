# PdaNet L4T

A small compatibility wrapper and system-tray frontend for using **PdaNet+ Wi-Fi Direct** with legacy NVIDIA L4T / Switchroot Linux systems where the upstream Linux client's nftables NAT path does not work.

This project does **not** reimplement PdaNet. It uses **xsqu1znt/PdaNetClientCLI-Linux** as the base engine (redsocks + dnscrypt-proxy + systemd integration), then replaces the incompatible Wi-Fi routing stage with `iptables-legacy` on affected L4T kernels.

## Tested configuration

Confirmed working in a real session:

- Nintendo Switch OLED
- Switchroot Ubuntu Noble
- Kernel: `4.9.140-l4t`
- Architecture: `arm64`
- Android host: POCO F7
- PdaNet+ Android: `5.32.0`
- Connection: PdaNet+ **WiFi Direct Hotspot**
- Upstream base: `xsqu1znt/PdaNetClientCLI-Linux`
- Tested upstream commit: `f20ae0e679f26d1703f6a99ffc1978fc7c7dd84f`
- Tested proxy: `192.168.49.1:8000`

Other Android phones and L4T devices may work, but the configuration above is what has actually been tested.

> **Release-candidate note:** the underlying manual compatibility path and tray behavior were confirmed on the tested Switch OLED. The bundled one-shot `install.sh` has been syntax-checked and built from those exact steps, but should receive a clean-install test before the project is labeled stable. See `docs/INSTALLER-TEST-CHECKLIST.md`.

## What the installer automates

The painful manual debugging should not be required for normal users. `install.sh`:

1. installs wrapper dependencies;
2. clones the upstream xsqu1znt client;
3. checks out the exact tested commit;
4. runs the upstream installer;
5. fixes `/usr/bin` vs `/usr/sbin` service executable paths using the paths actually installed on the machine;
6. removes dnscrypt-proxy options rejected by Noble's older dnscrypt-proxy;
7. verifies `iptables-legacy` NAT + REDIRECT support;
8. installs the L4T routing wrapper;
9. installs a PyQt system-tray app;
10. asks for the phone's PdaNet proxy IP and port;
11. creates one application-menu entry and autostarts the tray on login.

## Quick install

You need a temporary working Internet connection for the first install because packages and the upstream GitHub project must be downloaded.

```bash
git clone https://github.com/BulatPakoh/PdaNet-L4T-Switchroot.git
cd PdaNet-L4T-Switchroot
bash install.sh
```

Do **not** run `install.sh` itself with `sudo`; it asks for elevation only when needed.

Default proxy values are:

```text
192.168.49.1:8000
```

Use the values shown inside the PdaNet+ Android app if yours are different.

## Daily use

1. Android: open PdaNet+ and enable **WiFi Direct Hotspot**.
2. Linux: join the `DIRECT-...-PdaNet` Wi-Fi network.
3. Open the **PdaNet L4T** tray icon.
4. Choose **Connect**.
5. Approve the system authentication prompt.
6. The backend checks proxy reachability, starts redsocks + dnscrypt-proxy, applies the L4T rules and performs an HTTPS test before reporting success.

The tray menu also provides **Disconnect**, **Change Proxy**, **Show Status**, and **Quit**.

## Important networking limitation

PdaNet Wi-Fi Direct mode in the upstream xsqu1znt client carries **TCP and DNS**, not arbitrary UDP or ICMP. This wrapper does not remove that underlying limitation. Web browsing, Git, `apt`, `curl`, `wget`, and normal TCP downloads are the main target. `ping` is not a valid connectivity test for this mode. Some games, voice/video applications, VPNs, or software requiring arbitrary UDP may not work.

## Why this wrapper exists

The tested Switchroot kernel reports `4.9.140-l4t`. The upstream Wi-Fi mode expects nftables NAT. On the tested system, loading `nft_chain_nat` fails, while `iptables-legacy` NAT and `REDIRECT` work correctly. The wrapper therefore keeps the upstream proxy/DNS services but installs an isolated `PDANET` chain in the legacy NAT table.

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for the exact failures observed during testing.

## Diagnostics

```bash
bash diagnose.sh
```

Attach the output when reporting a compatibility issue. Review it before posting publicly if you have customized anything you consider sensitive.

## Uninstall

```bash
bash uninstall.sh
```

To also remove this wrapper's saved proxy configuration:

```bash
bash uninstall.sh --purge-config
```

The uninstaller intentionally leaves the separately installed **xsqu1znt/PdaNetClientCLI-Linux** base in place.

## Attribution and licensing

PdaNet L4T is an independent compatibility wrapper and is not affiliated with PdaNet/FoxFi or the upstream xsqu1znt project.

The upstream repository currently does not visibly include a license file in its repository root. For that reason this repository **does not vendor, copy, or relicense upstream source code**. `install.sh` clones the upstream repository directly and pins the tested commit. See [ATTRIBUTION.md](ATTRIBUTION.md).

The original code in this wrapper repository is released under the MIT License; see [LICENSE](LICENSE).
