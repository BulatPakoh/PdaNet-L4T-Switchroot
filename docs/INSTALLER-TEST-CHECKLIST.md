# v0.1.0 / v0.1.1 validation checklist

Core v0.1.0 WiFi Direct installation and daily-use behavior has been validated on the tested Nintendo Switch OLED / Switchroot Ubuntu Noble environment. The v0.1.1 development line additionally validates the optional OpenVPN TCP Full Tunnel.

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

## v0.1.1 Full Tunnel confirmed

- [x] `openvpn` and `libsecret-tools` are included in the required dependency set.
- [x] Installer re-run succeeds with all Full Tunnel dependencies already present.
- [x] Tray exposes Full Tunnel connect/disconnect/status controls.
- [x] A trusted OpenVPN TCP `.ovpn` profile can be selected from the tray.
- [x] Full Tunnel establishes `tun0` through the PdaNet HTTP proxy.
- [x] Discord voice changes from `No Route` in standard mode to working through Full Tunnel.
- [x] Stopping Full Tunnel immediately returns Discord voice to `No Route`.
- [x] Reconnecting Full Tunnel restores Discord voice.
- [x] Optional credentials can be stored through Secret Service/KWallet.
- [x] Saved OpenVPN password is not written to `~/.config/pdanet-l4t/full-tunnel.ini`.
- [x] Saved profile and auto-connect preference persist across reboot.
- [x] Tray autostarts after reboot with standard PdaNet disconnected and Full Tunnel auto-connect still enabled.
- [x] Main **Connect** starts standard PdaNet and the saved Full Tunnel.
- [x] Saved Full Tunnel reconnect does not ask for provider credentials again.
- [x] Combined standard + Full Tunnel startup uses one PolicyKit password prompt on the tested session.
- [x] Standard **Disconnect** also stops Full Tunnel cleanly.
- [x] Full Tunnel runtime files are included in uninstaller cleanup.
- [x] Full Tunnel keyring secret and user preferences are included in uninstaller cleanup.

A GPG/KWallet unlock prompt may still appear separately after login/reboot because it belongs to the desktop wallet configuration rather than the PdaNet L4T PolicyKit flow.

## Expected startup behavior

The installer registers the tray for login autostart but does **not** start it immediately when `install.sh` finishes. In that same desktop session, open **PdaNet L4T** from the application menu/search if immediate use is needed. Otherwise it starts automatically on the next login/reboot.

**Auto-connect Full Tunnel** does not mean standard PdaNet connects automatically at login. It means the saved Full Tunnel starts automatically after standard PdaNet is connected.

## Additional tests still useful

- [ ] Re-test **Change Proxy** end-to-end on a genuinely different proxy IP/port and confirm both redsocks and dnscrypt-proxy behavior.
- [x] Legacy normal-uninstall behavior was tested before the final uninstall redesign.
- [x] Test the final `pdanet-l4t-uninstall` command after reinstall: wrapper + xsqu1znt files/config/services are removed while shared Ubuntu packages remain.
- [x] Confirm `--remove-packages` with an empty ownership manifest performs full PdaNet cleanup without purging Ubuntu packages.
- [x] Re-test package ownership after installer fix: already-installed required packages are left unchanged and no `set to manually installed` lines appear.
- [x] Confirm an all-dependencies-present install leaves the package ownership manifest empty.
- [ ] Test `pdanet-l4t-uninstall --remove-packages` with a real newly installed allowlisted dependency and confirm ownership comes only from the PdaNet L4T APT transaction.
- [ ] Confirm a tampered/corrupt manifest containing a non-allowlisted package is rejected before any uninstall action.
- [x] Confirm the installed uninstall command works after the GitHub source checkout is temporarily moved/renamed.
- [x] Confirm the installed `pdanet-l4t-uninstall` command removes its own installed copy after completion; Bash command hashing may require `hash -r` before `command -v` reflects removal.
- [ ] Repeat installation on a pristine/freshly installed Switchroot Noble OS where the dependencies have never been installed before, including a state where `openvpn` and `libsecret-tools` are both initially absent.
- [ ] Exercise **Forget Saved Full Tunnel** end-to-end, then confirm the saved profile preference and keyring item are gone while an already-running tunnel remains connected as documented.
- [ ] Test a compatible OpenVPN TCP provider other than the currently confirmed Proton VPN Free profile.
- [ ] Expand testing to other Switch/L4T kernels and Android phones.
