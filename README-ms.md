# PdaNet L4T — Nota Ringkas BM

Ini ialah **compatibility layer khas untuk Switchroot / NVIDIA L4T lama** bagi menggunakan **PdaNet+ WiFi Direct Hotspot** pada kernel yang bermasalah dengan laluan NAT biasa.

Pada Nintendo Switch OLED yang diuji, kernel `4.9.140-l4t` tidak mempunyai sokongan nftables NAT yang diperlukan oleh client upstream, tetapi `iptables-legacy` masih boleh buat NAT + `REDIRECT` dengan betul.

PdaNet L4T guna **xsqu1znt/PdaNetClientCLI-Linux** sebagai base, kemudian tambah fix L4T/Noble, `iptables-legacy` fallback, config proxy, installer automatik dan system tray.

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

> **Tray selepas install:** installer akan daftar PdaNet L4T untuk autostart masa login, tetapi tray **tidak terus muncul dalam session yang sama selepas installer habis**. Selepas install, sama ada buka **PdaNet L4T** sekali dari application menu/search, atau logout/restart. Pada login seterusnya tray akan muncul secara automatik.

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

### Ujian game/network komuniti

Raw UDP dan ICMP gagal pada setup ujian sekarang, tetapi itu **tak semestinya bermaksud semua game akan gagal**. Ada game yang guna TCP, campuran protocol, relay server atau fallback lain.

Kalau kau test game atau app network-heavy, **bagitahu result walaupun ia berjaya**. Lagi bagus kalau report:

- nama game/app;
- login boleh atau tak;
- matchmaking/join session boleh atau tak;
- gameplay sebenar jalan atau tak;
- voice chat jalan atau tak;
- kernel Switchroot/L4T, model phone dan versi PdaNet+.

Buka GitHub issue dan beritahu apa yang jalan atau gagal supaya compatibility list dibina daripada ujian hardware sebenar, bukan andaian.

## Related projects

- **xsqu1znt/PdaNetClientCLI-Linux** — base yang project ini gunakan.
- **wtyler2505/pdanet-linux** — client PdaNet Linux yang lebih general dengan implementation sendiri, installer automatik, GUI GTK, redsocks/iptables, WiFi/USB workflow dan carrier-bypass features.

### Beza dengan wtyler2505/pdanet-linux

**wtyler2505/pdanet-linux** fokus pada pengalaman PdaNet untuk Linux general, khususnya distro Debian/Ubuntu-style; README dia senaraikan Linux Mint 22.2 Cinnamon sebagai platform yang diuji.

**PdaNet L4T** pula fokus pada masalah yang kita reproduce sendiri pada Switchroot:

- Nintendo Switch OLED + Switchroot Ubuntu Noble;
- kernel `4.9.140-l4t`;
- `nft_chain_nat` tak tersedia;
- `iptables-legacy` masih berfungsi;
- fix dnscrypt-proxy Noble 2.0.45;
- fix path `/usr/bin` vs `/usr/sbin`;
- lightweight tray untuk integration Switchroot.

Jadi memang ada overlap pada redsocks/iptables dan transparent routing, tetapi **scope utama PdaNet L4T ialah compatibility Switchroot / legacy NVIDIA L4T**, bukan general Linux desktop client.

Project ini tidak affiliated dengan PdaNet/FoxFi atau project upstream tersebut.

## Status ujian v0.1.0

Clean-application install daripada fresh GitHub clone telah diuji pada setup di atas. Installer, autostart selepas reboot/login, Connect, Disconnect, Quit, buka semula daripada application search dan reconnect semuanya berjaya. OS tidak dipasang semula dari kosong, jadi dependency package Ubuntu yang pernah dipasang sebelum ini masih ada semasa ujian.
