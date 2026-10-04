# PdaNet L4T — Nota Ringkas BM

Ini ialah compatibility wrapper untuk PdaNet+ WiFi Direct pada Switchroot / NVIDIA L4T lama yang gagal menggunakan routing `nftables` daripada client Linux asal.

## Setup yang telah betul-betul diuji

- Nintendo Switch OLED
- Switchroot Ubuntu Noble
- kernel `4.9.140-l4t`
- `arm64`
- POCO F7 sebagai phone host
- PdaNet+ Android `5.32.0`
- xsqu1znt/PdaNetClientCLI-Linux commit `f20ae0e679f26d1703f6a99ffc1978fc7c7dd84f`
- proxy `192.168.49.1:8000`

## Install

Perlu Internet sementara untuk install kali pertama.

```bash
git clone https://github.com/BulatPakoh/PdaNet-L4T-Switchroot.git
cd PdaNet-L4T-Switchroot
bash install.sh
```

Installer akan buat setup xsqu1znt, patch compatibility Noble/L4T, pasang `iptables-legacy` wrapper dan system tray secara automatik.

## Guna hari-hari

1. Phone: PdaNet+ → WiFi Direct Hotspot ON.
2. Ubuntu: connect Wi-Fi `DIRECT-...-PdaNet`.
3. Klik icon **PdaNet L4T** dalam system tray (`^`).
4. Tekan **Connect**.
5. Masukkan password Ubuntu bila popup authentication keluar.

Kalau IP/port phone lain berbeza, guna **Change Proxy**.

**Nota:** WiFi Direct mode ini membawa TCP + DNS, bukan arbitrary UDP/ICMP. Jangan guna `ping` sebagai ujian utama.
