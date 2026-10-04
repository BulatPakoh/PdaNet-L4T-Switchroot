# v0.1 installer validation checklist

Core v0.1 WiFi Direct installation and daily-use behavior has been validated on the tested Nintendo Switch OLED / Switchroot Ubuntu Noble environment.

## Confirmed

- [x] Temporary normal Internet works for installation.
- [x] `bash install.sh` completes from a normal user account.
- [x] Exact upstream commit is checked out.
- [x] Required upstream dependencies are detected/available.
- [x] Service executable paths are rewritten to the binaries actually present.
- [x] Noble dnscrypt-proxy `odoh_servers` / `http3` compatibility issue is handled.
- [x] `iptables-legacy` REDIRECT self-test passes.
- [x] One `PdaNet L4T` menu item is created.
- [x] Tray autostarts on the next login/reboot.
- [x] Single-instance protection prevents duplicate tray processes.
- [x] PdaNet WiFi Direct network can be used with the configured proxy.
- [x] Connect succeeds.
- [x] Browser/HTTPS Internet works after Connect.
- [x] Disconnect removes working Internet through the wrapper as expected.
- [x] Quit removes the tray.
- [x] Relaunch from application search works.
- [x] Reconnect after relaunch works.

## Expected startup behavior

The installer registers the tray for login autostart but does **not** start it immediately when `install.sh` finishes. In that same desktop session, open **PdaNet L4T** from the application menu/search if you want to use it immediately. Otherwise it starts automatically on the next login/reboot.

## Additional tests still useful

- [ ] Re-test **Change Proxy** end-to-end on a genuinely different proxy IP/port and confirm both redsocks and dnscrypt-proxy behavior.
- [x] Run `bash uninstall.sh` as a dedicated release test and verify that only the wrapper is removed while the separately installed xsqu1znt base remains.
- [ ] Repeat installation on a pristine/freshly installed Switchroot Noble OS where the dependencies have never been installed before.
- [ ] Expand testing to other Switch/L4T kernels and Android phones.
