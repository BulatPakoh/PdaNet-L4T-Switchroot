# PdaNet L4T — Nota Ringkas BM

Ini ialah **compatibility layer khas untuk Switchroot / NVIDIA L4T lama**, bukan cubaan membuat “PdaNet Linux pertama” atau menggantikan semua project PdaNet Linux yang sudah ada.

Project ini wujud sebab pada Nintendo Switch OLED yang diuji, kernel `4.9.140-l4t` tidak mempunyai laluan nftables NAT yang diperlukan oleh client upstream, tetapi `iptables-legacy` masih boleh buat NAT + `REDIRECT` dengan betul.

PdaNet L4T guna **xsqu1znt/PdaNetClientCLI-Linux** sebagai base, kemudian tambah fix L4T/Noble, `iptables-legacy` fallback, config proxy dan system tray.

## Apa project ini buat

- fokus pada Switchroot / legacy NVIDIA L4T;
- automasi fix yang telah diuji pada Switch OLED;
- transparent TCP redirect melalui redsocks;
- DNS melalui dnscrypt-proxy;
- tray Connect / Disconnect / Change Proxy / Status;
- autostart dan single-instance tray.

## Kenapa tak set proxy Ubuntu sahaja?

Kalau set proxy PdaNet `192.168.49.1:8000` secara manual, browser atau app yang memang ikut system proxy mungkin terus boleh Internet.

Masalahnya, bukan semua app ikut setting proxy desktop. Project ini redirect TCP secara transparent:

```text
App
 ↓
TCP biasa
 ↓
iptables-legacy
 ↓
redsocks
 ↓
PdaNet proxy
 ↓
Phone
```

Jadi user tak perlu configure proxy satu-satu untuk setiap app yang menggunakan TCP biasa.

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

## Limit WiFi Direct sekarang

Yang telah confirmed pada setup Switchroot ini:

- DNS ✅
- TCP ✅
- HTTPS ✅
- raw UDP ❌
- ICMP / ping ❌

Jadi jangan anggap semua game atau app UDP akan jalan melalui WiFi Direct mode ini.

**USB/TUN full-tunnel dirancang untuk v0.2** dan sengaja tidak dicampurkan ke v0.1 sekarang.

## Related projects

- **xsqu1znt/PdaNetClientCLI-Linux** — base yang project ini gunakan.
- **wtyler2505/pdanet-linux** — project PdaNet Linux yang lebih general dengan installer, GUI GTK, redsocks/iptables dan WiFi/USB workflow.

PdaNet L4T fokus pada gap yang lebih kecil: **Switchroot / legacy L4T**, terutamanya kes kernel `4.9.140-l4t` yang tiada `nft_chain_nat` tetapi masih ada `iptables-legacy`.

Project ini tidak claim cipta PdaNet, tidak claim first Linux client, dan tidak affiliated dengan PdaNet/FoxFi atau project upstream tersebut.
