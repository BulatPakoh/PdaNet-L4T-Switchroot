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

## Not yet claimed as confirmed

Other Switch models, other L4T kernel revisions, non-Switch NVIDIA L4T devices, other Android phone models, Wayland desktops, non-Debian distributions and non-default PdaNet proxy layouts should be considered **community testing targets**, not guaranteed support.
