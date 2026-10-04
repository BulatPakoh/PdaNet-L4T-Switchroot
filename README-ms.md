# PdaNet L4T — Nota Ringkas BM

Ini ialah **compatibility layer untuk Switchroot / NVIDIA L4T lama** bagi menggunakan **PdaNet+ WiFi Direct Hotspot** pada setup yang laluan nftables upstream tidak serasi dengan kernel L4T yang diuji.

Pada Nintendo Switch OLED yang diuji, kernel `4.9.140-l4t` tidak menyediakan `nft_chain_nat` yang diperlukan oleh laluan WiFi upstream, tetapi `iptables-legacy` NAT + `REDIRECT` masih berfungsi.

PdaNet L4T menggunakan **xsqu1znt/PdaNetClientCLI-Linux** sebagai base, kemudian menambah compatibility fix untuk L4T/Noble, routing `iptables-legacy`, konfigurasi proxy, installer dan system tray ringan.

Validasi semasa berdasarkan satu Nintendo Switch OLED dengan Switchroot Ubuntu Noble. Report daripada hardware lain dialu-alukan.

## Setup yang telah diuji

- Nintendo Switch OLED
- Switchroot Ubuntu Noble
- kernel `4.9.140-l4t`
- `arm64`
- KDE Plasma / X11
- POCO F7 sebagai Android host
- PdaNet+ Android `5.32.0`
- PdaNet+ WiFi Direct Hotspot
- proxy `192.168.49.1:8000`
- xsqu1znt/PdaNetClientCLI-Linux commit `f20ae0e679f26d1703f6a99ffc1978fc7c7dd84f`

Detail ujian ada dalam [docs/TESTED.md](docs/TESTED.md).

## Kenapa tak guna proxy desktop sahaja?

Proxy PdaNet memang boleh digunakan secara terus.

Pada setup Switchroot/KDE yang diuji:

```text
curl dengan --proxy secara terus   PASS
KDE/KIO                            PASS

curl biasa melalui KDE proxy       FAIL - DNS
Chrome melalui KDE proxy           FAIL - DNS
Chrome melalui PAC yang diuji      FAIL - tiada Internet
```

Keputusan ini khusus kepada setup yang diuji. Ia bukan bermaksud fungsi proxy KDE atau PdaNet rosak secara umum.

PdaNet L4T mengendalikan TCP dan DNS secara transparent:

```text
App
 |
TCP / DNS biasa
 |
iptables-legacy REDIRECT
 |
redsocks / dnscrypt-proxy
 |
PdaNet proxy
 |
Phone
```

Dengan PdaNet L4T aktif pada sistem yang sama, `curl` biasa dan Chrome berfungsi tanpa perlu set proxy untuk setiap aplikasi.

## Install

Perlu Internet sementara untuk install kali pertama.

```bash
git clone https://github.com/BulatPakoh/PdaNet-L4T-Switchroot.git
cd PdaNet-L4T-Switchroot
bash install.sh
```

Jangan jalankan `install.sh` sendiri dengan `sudo`. Installer akan minta elevation bila perlu.

Default proxy:

```text
192.168.49.1:8000
```

Gunakan IP dan port yang PdaNet+ tunjuk jika nilainya berbeza.

Installer akan:

- pasang hanya dependency yang masih tiada;
- clone dan pin commit upstream yang telah diuji;
- apply fix Noble/L4T;
- verify `iptables-legacy` NAT + `REDIRECT`;
- pasang routing wrapper dan PyQt tray;
- simpan config proxy;
- buat application-menu entry dan login autostart.

Tray tidak dilancarkan terus dalam desktop session yang sama selepas installer selesai. Buka **PdaNet L4T** dari application menu sekali, atau logout/reboot.

## Guna hari-hari

1. Hidupkan **WiFi Direct Hotspot** dalam PdaNet+.
2. Connect ke Wi-Fi `DIRECT-...-PdaNet`.
3. Buka tray **PdaNet L4T**.
4. Tekan **Connect**.
5. Approve authentication prompt.

Backend hanya melaporkan ONLINE selepas proxy, services, routing dan HTTPS validation berjaya.

Tray turut menyediakan **Disconnect**, **Change Proxy**, **Show Status** dan **Quit**.

## Limit WiFi Direct sekarang

Keputusan semasa:

```text
DNS       PASS
TCP       PASS
HTTPS     PASS
Raw UDP   FAIL
ICMP      FAIL
```

Web browsing, Git, `apt`, `curl`, `wget` dan aplikasi berasaskan TCP ialah target utama yang telah disahkan.

`ping` bukan success test yang sesuai untuk mode ini.

Aplikasi yang perlukan arbitrary UDP mungkin tidak berfungsi. Game perlu diuji satu-satu kerana ada yang menggunakan TCP, relay atau fallback transport.

USB/TUN full-tunnel diletakkan berasingan untuk v0.2.

## Related projects

### xsqu1znt/PdaNetClientCLI-Linux

Ini ialah upstream base yang digunakan oleh PdaNet L4T. Ia menyediakan architecture redsocks, dnscrypt-proxy, systemd dan client PdaNet Linux yang digunakan oleh project ini.

Source upstream tidak divendor atau diclaim sebagai code project ini. Installer clone upstream secara terus dan pin commit yang telah diuji.

### wtyler2505/pdanet-linux

`wtyler2505/pdanet-linux` ialah project PdaNet Linux berasingan untuk sistem Debian/Ubuntu-style yang lebih general.

Ia bukan dependency PdaNet L4T, tetapi commit `30b19c8` telah diuji pada Switch OLED / Switchroot yang sama sebagai alternative/reference.

Selepas command `iw` yang diperlukan dipasang, script WiFi project tersebut berjaya detect interface Switch dan network PdaNet WiFi Direct, tetapi Internet verification gagal pada setup Switchroot yang diuji.

Keputusan itu hanya untuk konfigurasi ujian ini dan **bukan** dakwaan bahawa project tersebut rosak atau tidak sesuai untuk platform sasarannya.

Detail penuh direkod dalam [docs/TESTED.md](docs/TESTED.md).

## Status ujian 0.1.0

Code `0.1.0` telah diuji daripada clean **application state** menggunakan fresh GitHub clone.

Installer, login autostart, single-instance tray, Connect, Disconnect, Quit, relaunch, reconnect, standalone uninstall dan package-state-safe reinstall telah disahkan.

OS tidak dipasang semula dari kosong sebelum ujian, jadi pristine-OS dependency test masih berguna sebagai coverage tambahan.

## Uninstall

Standard:

```bash
pdanet-l4t-uninstall
```

Ini membuang PdaNet L4T, routing, config/service PdaNet dan fail upstream yang dipasang oleh project ini sambil mengekalkan shared Ubuntu packages.

Untuk turut membuang dependency package yang benar-benar baru dipasang oleh installer:

```bash
pdanet-l4t-uninstall --remove-packages
```

Hanya package allowlist berikut boleh dianggap installer-owned:

```text
adb
dnscrypt-proxy
redsocks
python3-pyqt5
kdialog
nftables
```

Ia hanya layak dibuang jika APT transaction PdaNet L4T sendiri merekodkannya sebagai package baru.

Shared/core tools seperti `python3`, `git`, `curl`, `iptables` dan PolicyKit tidak auto-remove. Uninstaller juga menjalankan APT simulation dan berhenti jika package tambahan yang tidak direkod turut dicadangkan untuk dibuang.

Folder source GitHub sengaja dikekalkan.

## Attribution

PdaNet L4T ialah independent compatibility project dan tidak affiliated dengan PdaNet/FoxFi, xsqu1znt, wtyler2505, Switchroot, Nintendo atau NVIDIA.

Code asal dalam repository ini menggunakan MIT License. Lihat [ATTRIBUTION.md](ATTRIBUTION.md) dan [LICENSE](LICENSE).
