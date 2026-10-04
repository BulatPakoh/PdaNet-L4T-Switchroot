# Changelog

## 0.1.1 - Unreleased

- Adds a generic OpenVPN TCP Full Tunnel mode on top of the existing PdaNet HTTP proxy path.
- Adds tray controls to choose a trusted TCP `.ovpn` profile, enter provider credentials, connect/disconnect Full Tunnel, and show tunnel status.
- Full Tunnel prefers provider port 443 automatically when a TCP profile contains a port-443 remote, while preserving non-443 TCP profiles when no port-443 remote exists.
- OpenVPN credentials are passed through a temporary mode-0600 file for connection startup; optional remembered credentials are stored through the desktop Secret Service/keyring rather than in plaintext PdaNet configuration.
- Adds optional saved Full Tunnel profile, secure keyring-backed credentials, auto-connect, profile replacement and a 'Forget Saved Full Tunnel' control.
- Auto-connect from the main tray Connect action now performs standard PdaNet and saved Full Tunnel startup in one privileged backend transaction, avoiding a second PolicyKit password prompt in the normal flow.
- Standard PdaNet L4T disconnect now also stops the Full Tunnel cleanly.
- Manual proof-of-concept on the tested Switch OLED showed Discord voice changing from `No Route` without the tunnel to a working voice connection through `tun0`; stopping OpenVPN immediately returned Discord to `No Route`.
- The tested proof used Proton VPN Free with an OpenVPN TCP profile. Proton is a tested provider, not a hardcoded dependency; the feature targets compatible OpenVPN TCP profiles.

## 0.1.0 - 2026-10-04 - Initial WiFi Direct release

- Confirmed on Nintendo Switch OLED / Switchroot Ubuntu Noble / kernel 4.9.140-l4t.
- Clean-application installation from a fresh GitHub clone completed successfully.
- Confirmed login/reboot autostart, Connect, Disconnect, Quit, application-menu relaunch and reconnect.
- Adds a standalone `pdanet-l4t-uninstall` command so removal does not depend on keeping the GitHub source checkout.
- Confirmed the standalone uninstaller works with the GitHub source checkout moved aside, removes PdaNet L4T + xsqu1znt files/config/services while keeping shared Ubuntu packages, and deletes its own installed copy after completion.
- Final uninstall design removes PdaNet L4T plus the xsqu1znt files/configuration installed by this project while keeping shared Ubuntu packages by default.
- Adds optional `--remove-packages` mode backed by a narrow PdaNet dependency allowlist, ownership captured from the actual PdaNet L4T APT transaction, and an APT safety simulation; unrelated concurrent package installs cannot enter the manifest.
- Installer now sends only missing packages to APT, avoiding the side effect where already-installed automatic packages could be marked as manually installed.
- Confirmed the package-state fix on Switchroot Noble: with all dependencies already present, APT is not invoked for package installation, no manual/auto package state is changed, and the ownership manifest remains empty.
- Package removal rejects manifest entries outside the built-in allowlist before any uninstall action, protecting against a corrupted or manually altered manifest.
- Documents that the installer registers login autostart but does not launch the tray immediately in the same session.
- Uses xsqu1znt/PdaNetClientCLI-Linux pinned to commit `f20ae0e679f26d1703f6a99ffc1978fc7c7dd84f`.
- Replaces the incompatible upstream nftables WiFi routing path with an isolated `iptables-legacy` NAT chain.
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
- Documents current WiFi Direct results: DNS/TCP/HTTPS confirmed; raw UDP and ICMP failed on the tested setup.
- Documents direct PdaNet proxy, KDE manual proxy and KDE PAC A/B testing.
- Records `wtyler2505/pdanet-linux` commit `30b19c8` as a tested alternative/reference on the same Switchroot hardware, including its failed Internet verification on the tested PdaNet WiFi Direct workflow.
- Invites community game/app reports, including successful results, to build a real compatibility list.

### Test-scope note

The v0.1.0 clean-install validation used a clean **application** state rather than a freshly reinstalled OS. Ubuntu dependency packages from earlier development were still installed. A pristine-OS dependency test remains useful additional coverage.

### Roadmap

- USB/TUN full-tunnel work is tracked separately for v0.2 and is not mixed into the v0.1 WiFi Direct version.
