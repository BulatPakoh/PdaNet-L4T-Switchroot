# Tested hardware/software matrix

## Confirmed PASS

| Component | Tested value |
|---|---|
| Device | Nintendo Switch OLED |
| Linux | Switchroot Ubuntu Noble |
| Kernel | 4.9.140-l4t |
| Architecture | arm64 |
| Android host | POCO F7 |
| PdaNet+ Android | 5.32.0 |
| Mode | WiFi Direct Hotspot |
| Proxy | 192.168.49.1:8000 |
| Upstream | xsqu1znt/PdaNetClientCLI-Linux |
| Upstream commit | f20ae0e679f26d1703f6a99ffc1978fc7c7dd84f |
| L4T routing | iptables-legacy |
| GUI | PyQt5 system tray |
| Desktop | KDE Plasma / X11 |
| OpenVPN | 2.6.19-0ubuntu0.24.04.4 |
| Keyring helper | libsecret-tools 0.21.4-1build3 |
| Full Tunnel provider test | Proton VPN Free, Singapore OpenVPN TCP profile |

## v0.1.0 clean-application install result

A clean-application test was performed after removing the active PdaNet L4T wrapper, upstream user binaries, PdaNet-specific systemd units/configuration, runtime marker and legacy NAT rules, while keeping a backup outside the active paths.

From a fresh clone of this repository:

- `bash install.sh` completed without errors;
- the pinned xsqu1znt upstream checkout was cloned again;
- wrapper files, system configuration, desktop entry and login autostart were recreated;
- after reboot/login, exactly one tray instance appeared automatically;
- Connect restored working Internet access;
- Disconnect removed that access as expected;
- Quit removed the tray;
- launching PdaNet L4T again from application search worked;
- reconnecting from the relaunched tray worked;
- Quit worked again.

The installer intentionally does not launch the tray immediately at the end of installation. In the current desktop session the user can open **PdaNet L4T** manually; otherwise it starts automatically on the next login/reboot.

### Test scope note

This was a **clean application state**, not a freshly reinstalled OS. Ubuntu dependency packages such as redsocks, dnscrypt-proxy, PyQt5 and iptables had already been installed during earlier development/testing. The installer still re-ran dependency checks and rebuilt the PdaNet-specific application state from the fresh clone.

Package-state behavior was also re-tested after the installer was changed to send only missing packages to APT. With all required packages already present, the installer did not invoke APT package installation, did not change manual/automatic package state, and left the installer-owned package manifest empty.

## v0.1.1 OpenVPN TCP Full Tunnel result

The `0.1.1-dev` branch was tested on the same Switch OLED / Switchroot Noble system after the standard WiFi Direct mode had already been validated.

The Full Tunnel architecture under test was:

```text
Application TCP / UDP
        |
       tun0
        |
OpenVPN TCP
        |
PdaNet HTTP proxy 192.168.49.1:8000
        |
Android phone
```

This is a layered workaround. It does not make the underlying PdaNet WiFi Direct path provide raw UDP. OpenVPN accepts application traffic through `tun0` and carries it inside a TCP session that can traverse the PdaNet HTTP proxy.

Tested provider/profile:

- Proton VPN Free;
- Singapore OpenVPN TCP profile;
- TCP remote port 443 selected when available;
- provider-issued OpenVPN credentials.

Proton is a tested provider only. It is not hardcoded into PdaNet L4T, and the Proton application is not installed by this project.

### Manual tunnel proof

Before the tray integration, the OpenVPN profile was tested manually with the PdaNet HTTP proxy added to a working copy.

Observed sequence:

- TCP connection to `192.168.49.1:8000`: **PASS**;
- OpenVPN peer connection through the proxy: **PASS**;
- `tun0` created: **PASS**;
- address assigned on `tun0`: **PASS**;
- default traffic split through the OpenVPN tunnel: **PASS**;
- OpenVPN reported `Initialization Sequence Completed`: **PASS**.

Using the normal Proton account password produced `AUTH_FAILED`, while the provider-issued OpenVPN credentials succeeded. No credential values are recorded in this repository.

### Discord/Vesktop A/B test

Discord behavior was tested using Vesktop 1.6.7 arm64. The tested Switchroot graphics stack required a separate Vesktop launch workaround; that graphics workaround is independent of PdaNet L4T networking.

| Test | Standard PdaNet | Full Tunnel |
|---|---:|---:|
| Discord text load/send | PASS | PASS |
| GIF | PASS | PASS |
| Image load/download | PASS | PASS |
| Image upload | PASS | PASS |
| Discord voice | FAIL - `No Route` | PASS |

A control test on a normal phone hotspot allowed Discord voice to connect successfully. This confirmed that the tested Vesktop/audio/network stack could establish Discord voice when the network path allowed it.

With Full Tunnel active, Discord voice connected successfully. Stopping OpenVPN caused an immediate disconnect followed by `Checking Route` / `No Route`. Reconnecting the Full Tunnel restored voice.

This is evidence of UDP-capable application traffic through `tun0`; it is not evidence that the underlying PdaNet WiFi Direct proxy gained raw UDP support.

### Tray, keyring and auto-connect validation

The final tested `0.1.1-dev` tray flow produced:

| Check | Result |
|---|---|
| Full Tunnel controls appear in tray | PASS |
| Select original trusted TCP `.ovpn` profile | PASS |
| Manual Full Tunnel connect | PASS |
| Manual Full Tunnel disconnect | PASS |
| Manual reconnect | PASS |
| Save credentials through Secret Service/KWallet | PASS |
| No OpenVPN password stored in `full-tunnel.ini` | PASS |
| Saved profile persists | PASS |
| Auto-connect setting persists | PASS |
| Reboot/login tray autostart | PASS |
| After reboot, standard mode remains disconnected until user chooses Connect | PASS |
| Main Connect starts standard mode + saved Full Tunnel | PASS |
| Saved Full Tunnel reconnects without asking for provider credentials again | PASS |
| Combined Connect requires one PolicyKit password prompt on the tested session | PASS |

On the tested KDE/KWallet setup, a GPG/KWallet unlock prompt appeared after reboot when the desktop accessed saved network/keyring secrets. That prompt is separate from the PdaNet L4T PolicyKit authorization flow.

The installer was re-run successfully after the Full Tunnel dependencies had already been installed. Because `openvpn` and `libsecret-tools` were already present before the final installer run, a pristine-OS test where those packages are initially absent remains unclaimed.

## Direct PdaNet proxy and KDE proxy tests

These tests were performed while connected to the phone's PdaNet WiFi Direct network using proxy `192.168.49.1:8000`.

Unless stated otherwise, PdaNet L4T was OFF so the desktop/native proxy path could be evaluated independently.

### Explicit HTTP proxy

Command:

```bash
curl -I --proxy http://192.168.49.1:8000 https://example.com
```

Result: **PASS**

The PdaNet HTTP proxy itself was reachable and returned a successful HTTPS connection without PdaNet L4T being active.

### KDE manual proxy

KDE was configured with the PdaNet address as the HTTP and HTTPS proxy.

Results:

| Test | Result |
|---|---|
| `kioclient5 cat https://example.com` | PASS |
| normal `curl -I https://example.com` | FAIL - DNS resolution |
| Chrome | FAIL - DNS resolution |

This shows that the desktop proxy path worked for KDE/KIO-aware traffic on the tested setup, but did not transparently cover every application.

### KDE proxy auto-configuration / PAC test

KDE was switched to proxy auto-configuration using:

```text
http://192.168.49.1:8000
```

Chrome still failed to obtain working Internet access on the tested setup.

This is only a result for the tested Switchroot Noble / KDE / Chrome configuration. It is not a claim that PdaNet PAC or KDE PAC support fails on other platforms.

### PdaNet L4T A/B result

With PdaNet L4T enabled on the same PdaNet WiFi Direct connection:

- normal `curl -I https://example.com` passed;
- Chrome worked;
- the backend HTTPS validation passed.

This is the practical behavior the compatibility layer is intended to provide: normal TCP/DNS handling without requiring each application to use the desktop proxy configuration directly.

## Network protocol result

The tested **standard** WiFi Direct proxy path produced:

| Protocol/use | Result |
|---|---|
| DNS through PdaNet L4T | PASS |
| TCP | PASS |
| HTTPS | PASS |
| Raw UDP/STUN test | FAIL |
| ICMP/ping | FAIL |
| Discord voice | FAIL - `No Route` |

Standard mode should therefore not be described as a general full-IP tunnel.

With the optional OpenVPN TCP Full Tunnel active, application traffic routed through `tun0` successfully supported the tested Discord voice workload. Direct raw UDP and ICMP capability of the underlying PdaNet WiFi Direct proxy remains unchanged.

A failed `ping` is expected for standard mode and is not a valid Internet success test for that path.

## Existing alternative test: wtyler2505/pdanet-linux

A separate existing Linux project, `wtyler2505/pdanet-linux`, was evaluated to determine whether its current WiFi workflow already solved the same Switchroot use case.

Tested commit:

```text
30b19c8a775a03bf78cbd5c7ce47a6f05b4c0b6c
```

The repository was cloned fresh. Its full installer was not run during this comparison; the current WiFi workflow was tested directly to avoid unnecessary system-wide installer side effects.

### First run

Running:

```bash
sudo ./pdanet-wifi-connect
```

initially failed with:

```text
iw: command not found
Error: No WiFi interface found
```

The tested WiFi script invokes `iw`, but `iw` was not installed on the Switchroot system at that point.

After installing `iw`, the actual PdaNet WiFi Direct test was repeated.

### PdaNet WiFi Direct result after installing iw

The script correctly detected:

- WiFi interface `wlp1s0`;
- the `DIRECT-...-PdaNet` network;
- PdaNet gateway `192.168.49.1`.

However, its own connectivity checks reported:

```text
[3/5] Verifying internet...
Warning: Cannot reach internet

[5/5] Final verification...
Warning: Verification failed (may still work)
```

The script then still printed:

```text
WiFi connection established!
```

No working PdaNet Internet connection was obtained through that tested WiFi workflow on this Switchroot system.


### Code-path note

Inspection of the tested `pdanet-wifi-connect` path showed that it applies WiFi/carrier-bypass firewall changes but does not start the redsocks transparent proxy path or apply the repository's separate transparent TCP redirect script.

The tested system's plain `iptables` command was:

```text
iptables v1.8.10 (nf_tables)
```

while PdaNet L4T intentionally uses `iptables-legacy` on this L4T kernel.

This comparison is included only to document why an existing alternative was not adopted for this specific Switchroot target. It is **not** a claim that `wtyler2505/pdanet-linux` is broken or unsuitable for its documented Linux targets.

### Cleanup and regression check

After the alternative test:

- added nft-backend NAT rules were removed;
- remaining WiFi stealth/TCPMSS/filter rules were checked and removed;
- `net.ipv6.conf.wlp1s0.disable_ipv6` was confirmed as `0`;
- PdaNet L4T was enabled again on the PdaNet WiFi Direct network;
- PdaNet L4T completed its proxy, service, routing and HTTPS checks successfully.

This confirmed that the comparison test had not broken the working PdaNet L4T setup.

## Not yet claimed as confirmed

Other Switch models, other L4T kernel revisions, non-Switch NVIDIA L4T devices, other Android phone models, Wayland desktops, non-Debian distributions and non-default PdaNet proxy layouts should be considered **community testing targets**, not guaranteed support.

A pristine/freshly installed Switchroot Noble OS where the dependencies have never previously been installed also remains useful additional installer coverage. In particular, the final `0.1.1-dev` installer has not yet been validated from a state where `openvpn` and `libsecret-tools` are both absent before installation.

Compatible OpenVPN TCP providers other than the tested Proton VPN Free profile should also be considered community testing targets until reproduced on real hardware.
