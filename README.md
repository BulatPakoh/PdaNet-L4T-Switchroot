# PdaNet L4T

A **Switchroot / legacy NVIDIA L4T compatibility layer** for using **PdaNet+ WiFi Direct Hotspot** on older kernels where the usual Linux routing path can fail.

On the tested Nintendo Switch OLED / Switchroot system, the upstream WiFi path expected nftables NAT support that the kernel did not provide, while `iptables-legacy` NAT + `REDIRECT` worked correctly. PdaNet L4T automates that compatibility path and adds a lightweight tray frontend for daily use.

PdaNet L4T uses **xsqu1znt/PdaNetClientCLI-Linux** as its base engine (redsocks + dnscrypt-proxy + systemd integration), then adds the Switchroot/L4T fixes, proxy configuration, installer logic and tray integration confirmed on the tested hardware.

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

> **Release-candidate note:** the manual compatibility path, one-shot installer, backend, tray Connect/Disconnect, Quit behavior and single-instance tray handling have all been tested on the configuration above. A clean-application install test is still being completed before the project is labeled stable. See `docs/INSTALLER-TEST-CHECKLIST.md`.

## Why not just set the proxy in Ubuntu?

PdaNet WiFi Direct exposes an HTTP proxy, and manually setting that proxy in Ubuntu can be enough for software that **honors the desktop/system proxy setting**.

That does not automatically cover every application. Some programs ignore the desktop proxy configuration entirely. This project uses transparent TCP redirection so ordinary applications can open TCP connections without each application being configured separately:

```text
Application
    |
normal TCP connection
    |
iptables-legacy REDIRECT
    |
redsocks
    |
PdaNet HTTP CONNECT proxy
    |
Android phone
```

DNS is handled through the PdaNet-specific dnscrypt-proxy configuration.

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

The currently tested **WiFi Direct proxy path** is confirmed for DNS, TCP and HTTPS. Raw UDP and ICMP tests on the tested Switchroot setup did **not** pass.

That means:

- web browsing, Git, `apt`, `curl`, `wget`, normal TCP downloads and many TCP-based applications are the main confirmed target;
- `ping` is not a valid success test for this WiFi Direct mode;
- some games, voice/video applications, VPNs or software that require arbitrary UDP may not work through this WiFi Direct path.

**USB/TUN full-tunnel support is planned separately for v0.2** and is intentionally not mixed into the current v0.1 WiFi Direct compatibility work.

### Community game/network testing

Raw UDP and ICMP failed in the current test setup, but that does **not** automatically prove that every game will fail. Some games may use TCP, mixed transport, relay services or fallback paths.

If you test a game or network-heavy app, please report the result — **successful reports are useful too**. Include:

- game/app name;
- whether login works;
- whether matchmaking/session join works;
- whether actual gameplay works;
- whether voice chat works;
- your Switchroot/L4T kernel, Android phone and PdaNet+ version.

Open a GitHub issue and tell us what worked or failed so the compatibility list can grow from real hardware tests instead of guesses.

## Why this wrapper exists

The tested Switchroot kernel reports `4.9.140-l4t`. On that system:

```text
nft_chain_nat: unavailable
iptables-legacy: available
```

The upstream WiFi routing path therefore could not use the expected nftables NAT support, while `iptables-legacy` NAT and `REDIRECT` worked correctly. PdaNet L4T keeps the upstream proxy/DNS services but installs an isolated `PDANET` chain in the legacy NAT table.

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for the exact failures observed during testing.

## Related projects

### xsqu1znt/PdaNetClientCLI-Linux

This is the **upstream base used by PdaNet L4T**. It supplies the Linux PdaNet client, redsocks integration, dnscrypt-proxy integration, systemd units and USB support that this project builds on.

PdaNet L4T does not vendor or claim ownership of that upstream code.

### wtyler2505/pdanet-linux

A separate, broader Linux PdaNet project with its own reverse-engineered client, automated installer, GTK GUI, redsocks/iptables routing, WiFi/USB workflows and carrier-bypass features. Its documented target is general Debian/Ubuntu-style Linux, with Linux Mint 22.2 Cinnamon listed as a tested platform.

The practical difference is scope and architecture:

| | wtyler2505/pdanet-linux | PdaNet L4T |
|---|---|---|
| Main goal | General Linux PdaNet client | Switchroot / legacy L4T compatibility |
| Base | Its own implementation | Builds on xsqu1znt/PdaNetClientCLI-Linux |
| Documented tested platform | Linux Mint 22.2 Cinnamon | Nintendo Switch OLED / Switchroot Ubuntu Noble |
| Legacy L4T `4.9.140-l4t` | Not documented as a tested target | Confirmed |
| Missing `nft_chain_nat` handling | Not documented as a target | Core reason this wrapper exists |
| `iptables-legacy` fallback | Not documented in its current README | Explicitly tested and used |
| GUI style | Full GTK application | Small PyQt tray utility |
| Extra focus | Carrier-bypass / stealth features | L4T compatibility and minimal integration |

So the overlap is real — both can use redsocks/iptables-style transparent routing — but **PdaNet L4T specifically targets the Switchroot kernel compatibility problem that was reproduced on real Switch OLED hardware**.

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

PdaNet L4T is an independent compatibility wrapper and is not affiliated with PdaNet/FoxFi, xsqu1znt, or wtyler2505.

The upstream xsqu1znt repository currently does not visibly include a license file in its repository root. For that reason this repository **does not vendor, copy, or relicense upstream source code**. `install.sh` clones the upstream repository directly and pins the tested commit. See [ATTRIBUTION.md](ATTRIBUTION.md).

The original code in this wrapper repository is released under the MIT License; see [LICENSE](LICENSE).
