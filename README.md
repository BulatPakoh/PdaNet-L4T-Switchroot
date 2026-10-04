# PdaNet L4T

A **Switchroot / legacy NVIDIA L4T compatibility layer** for using **PdaNet+ WiFi Direct Hotspot** on systems where the upstream Linux routing path is incompatible with the tested legacy L4T kernel and desktop proxy settings are not sufficient for every application.

On the tested Nintendo Switch OLED / Switchroot Ubuntu Noble system, the upstream `xsqu1znt/PdaNetClientCLI-Linux` WiFi path expected nftables NAT support that the kernel did not provide, while `iptables-legacy` NAT + `REDIRECT` worked correctly.

PdaNet L4T keeps the upstream redsocks and dnscrypt-proxy architecture, replaces the incompatible routing path with a tested `iptables-legacy` implementation, applies Noble/L4T compatibility fixes, and adds a lightweight system-tray frontend.

Current validation is based on one Nintendo Switch OLED / Switchroot Ubuntu Noble system. Additional real-hardware reports are welcome.

## Tested configuration

Confirmed working on:

- Nintendo Switch OLED
- Switchroot Ubuntu Noble
- Kernel `4.9.140-l4t`
- Architecture `arm64`
- KDE Plasma / X11
- Android host: POCO F7
- PdaNet+ Android `5.32.0`
- PdaNet+ WiFi Direct Hotspot
- Proxy `192.168.49.1:8000`
- Upstream base: `xsqu1znt/PdaNetClientCLI-Linux`
- Tested upstream commit: `f20ae0e679f26d1703f6a99ffc1978fc7c7dd84f`

Other phones, Switch models, L4T kernels and NVIDIA L4T devices may work, but are not currently claimed as confirmed.

See [docs/TESTED.md](docs/TESTED.md) for detailed test results.

## Why not just use the desktop proxy?

PdaNet WiFi Direct exposes an HTTP proxy, and using that proxy directly is valid.

On the tested Switchroot/KDE setup:

```text
Explicit curl --proxy       PASS
KDE/KIO proxy access        PASS

Normal curl via KDE proxy   FAIL - DNS resolution
Chrome via KDE proxy        FAIL - DNS resolution
Chrome via tested PAC path  FAIL - no Internet
```

These results are specific to the tested system and do not mean KDE proxy support or PdaNet proxying is generally broken.

The important difference is that desktop proxy settings depend on applications actually using that proxy configuration.

PdaNet L4T instead redirects normal TCP and DNS traffic transparently:

```text
Application
    |
normal TCP / DNS
    |
iptables-legacy REDIRECT
    |
redsocks / dnscrypt-proxy
    |
PdaNet HTTP proxy
    |
Android phone
```

With PdaNet L4T enabled on the same system, normal `curl` and Chrome worked without per-application proxy configuration.

## Why this compatibility layer exists

The tested Switchroot kernel is:

```text
4.9.140-l4t
```

On that system:

```text
nft_chain_nat     unavailable
iptables-legacy   available
```

The upstream nftables NAT path therefore could not be used, while legacy NAT + `REDIRECT` worked correctly.

PdaNet L4T keeps the upstream proxy services but installs an isolated `PDANET` chain using `iptables-legacy`.

Two additional compatibility problems were reproduced during testing:

- upstream systemd executable paths did not match the installed `redsocks` / `dnscrypt-proxy` locations;
- Noble's dnscrypt-proxy `2.0.45` rejected the upstream `odoh_servers` and `http3` options.

The installer handles both automatically.

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for the actual failures observed during development.

## Install

A temporary working Internet connection is required for the first installation.

```bash
git clone https://github.com/BulatPakoh/PdaNet-L4T-Switchroot.git
cd PdaNet-L4T-Switchroot
bash install.sh
```

Do **not** run `install.sh` itself with `sudo`.

The installer requests elevation only for operations that require it.

Default PdaNet proxy:

```text
192.168.49.1:8000
```

Use the IP and port shown by PdaNet+ if yours are different.

The installer:

- installs only missing dependencies;
- clones and pins the tested upstream commit;
- applies the Noble/L4T compatibility fixes;
- verifies `iptables-legacy` NAT + `REDIRECT`;
- installs the routing wrapper and PyQt tray;
- stores the PdaNet proxy configuration;
- creates the application-menu and login-autostart entries.

Package ownership is tracked conservatively so unrelated Ubuntu packages are not removed by the uninstaller.

### Tray after installation

The tray is registered for login autostart but is not launched automatically in the same desktop session where installation finishes.

Open **PdaNet L4T** from the application menu once, or log out/reboot.

## Daily use

1. Enable **WiFi Direct Hotspot** in PdaNet+.
2. Join the `DIRECT-...-PdaNet` Wi-Fi network.
3. Open the **PdaNet L4T** tray.
4. Choose **Connect**.
5. Approve the authentication prompt.

Connection is only reported successful after:

```text
PdaNet proxy check
        |
proxy/DNS configuration
        |
proxy services started
        |
iptables-legacy routing applied
        |
HTTPS validation
        |
ONLINE
```

The tray also provides **Disconnect**, **Change Proxy**, **Show Status**, and **Quit**.

## Networking limitations

Current WiFi Direct results:

```text
DNS       PASS
TCP       PASS
HTTPS     PASS
Raw UDP   FAIL
ICMP      FAIL
```

Web browsing, Git, `apt`, `curl`, `wget` and normal TCP-based applications are the main confirmed targets.

`ping` is not a valid success test for this mode.

Applications requiring arbitrary UDP may not work. Games should be tested individually because some use TCP, relay services or fallback transports.

USB/TUN full-tunnel work is tracked separately for v0.2.

## Related projects

### xsqu1znt/PdaNetClientCLI-Linux

This is the **upstream base used by PdaNet L4T**.

It provides the underlying redsocks, dnscrypt-proxy, systemd and PdaNet Linux client architecture.

PdaNet L4T does not vendor or claim ownership of that upstream code. The installer downloads it directly and pins the tested commit.

### wtyler2505/pdanet-linux

`wtyler2505/pdanet-linux` is a separate Linux PdaNet project targeting general Debian/Ubuntu-style systems.

It is not used by PdaNet L4T, but commit `30b19c8` was evaluated on the same Switch OLED / Switchroot test system as an existing alternative.

After its required `iw` command was installed, its WiFi script detected both the Switch Wi-Fi interface and the PdaNet WiFi Direct network, but its Internet verification failed on the tested setup.

That result is specific to this Switchroot/L4T configuration and does **not** mean the project is broken or unsuitable for its documented targets.

It is listed here only as a tested alternative/reference.

Detailed results are recorded in [docs/TESTED.md](docs/TESTED.md).

## Validation status

The current `0.1.0` code has been validated from a clean **application state** using a fresh GitHub clone.

Confirmed tests include installer completion, login autostart, single-instance tray behavior, Connect, Disconnect, Quit, relaunch, reconnect, standalone uninstall and package-state-safe reinstall behavior.

The operating system itself was not freshly installed before validation, so a pristine-OS dependency test remains useful additional coverage.

See [docs/INSTALLER-TEST-CHECKLIST.md](docs/INSTALLER-TEST-CHECKLIST.md).

## Diagnostics

Run:

```bash
bash diagnose.sh
```

Useful diagnostic data includes kernel, architecture, distro, iptables backend, `iptables-legacy` availability, proxy service versions, service state, listening ports and the pinned upstream commit.

Review the output before posting it publicly.

## Compatibility reports

Real-hardware reports are welcome, including successful results.

Useful information includes the Switch/L4T device, Linux version, kernel, Android phone, PdaNet+ version, proxy address, installation result, Connect/Disconnect result and application/game behavior.

Compatibility should be based on reproduced hardware tests rather than assumptions.

## Uninstall

Standard removal:

```bash
pdanet-l4t-uninstall
```

This removes the PdaNet L4T application state, routing, PdaNet-specific configuration/services and upstream files installed by this project while keeping shared Ubuntu packages.

To also remove dependency packages that were newly installed by PdaNet L4T:

```bash
pdanet-l4t-uninstall --remove-packages
```

Package removal is deliberately conservative.

Only the following allowlisted packages can be considered installer-owned:

```text
adb
dnscrypt-proxy
redsocks
python3-pyqt5
kdialog
nftables
```

They are eligible only when the actual PdaNet L4T APT transaction recorded them as newly installed.

Shared/core tools such as `python3`, `git`, `curl`, `iptables` and PolicyKit are never automatically removed.

The uninstaller also runs an APT simulation and stops if additional unrecorded packages would be removed.

The GitHub source checkout is intentionally preserved.

## Attribution and licensing

PdaNet L4T is an independent compatibility project and is not affiliated with PdaNet/FoxFi, xsqu1znt, wtyler2505, Switchroot, Nintendo or NVIDIA.

PdaNet+ is third-party software and remains subject to its own terms.

The `xsqu1znt/PdaNetClientCLI-Linux` repository did not visibly include a license file in its repository root when this project was prepared. For that reason this repository does not copy, vendor or relicense upstream source code.

Original code in this repository is released under the MIT License.

See [ATTRIBUTION.md](ATTRIBUTION.md) and [LICENSE](LICENSE).
