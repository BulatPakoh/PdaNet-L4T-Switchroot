# Changelog

## 0.1.0 - Initial stable WiFi Direct release

- Confirmed on Nintendo Switch OLED / Switchroot Ubuntu Noble / kernel 4.9.140-l4t.
- Clean-application installation from a fresh GitHub clone completed successfully.
- Confirmed login/reboot autostart, Connect, Disconnect, Quit, application-menu relaunch and reconnect.
- Documents that the installer registers login autostart but does not launch the tray immediately in the same session.
- Uses xsqu1znt/PdaNetClientCLI-Linux pinned to commit f20ae0e679f26d1703f6a99ffc1978fc7c7dd84f.
- Replaces incompatible nftables Wi-Fi routing with an isolated iptables-legacy NAT chain.
- Adds proxy IP/port configuration.
- Updates both redsocks and dnscrypt-proxy when proxy settings change.
- Handles Noble dnscrypt-proxy compatibility (`odoh_servers`, `http3`).
- Patches upstream systemd executable paths to installed binaries.
- Adds Connect / Disconnect / Change Proxy / Status system-tray UI.
- Adds login autostart and duplicate-tray protection.
- Adds rollback after failed HTTPS validation.
- Adds diagnostics and troubleshooting documentation based on real test failures.
- Fixes KDE tray Quit cleanup so the icon is hidden before the Qt event loop exits.
- Adds an in-process file lock so autostart/session-restore races cannot create duplicate tray instances.
- Documents current WiFi Direct results: DNS/TCP/HTTPS confirmed; raw UDP and ICMP not confirmed on the tested setup.
- Invites community game/app reports, including successful results, to build a real compatibility list.

### Test-scope note

The v0.1.0 clean-install validation used a clean **application** state rather than a freshly reinstalled OS. Ubuntu dependency packages from earlier development were still installed. A pristine-OS dependency test remains useful additional coverage.

### Roadmap

- USB/TUN full-tunnel work is tracked separately for v0.2 and is not mixed into the v0.1 WiFi Direct release.
