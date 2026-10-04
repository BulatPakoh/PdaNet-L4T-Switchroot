# Installer release-candidate checklist

The manual compatibility path has been confirmed on the tested Switch OLED. Before calling the automated installer stable, test this repository on a clean/fresh Switchroot Noble environment or a restorable backup.

1. Temporary normal Internet works.
2. `bash install.sh` completes from a normal user account.
3. Exact upstream commit is checked out.
4. Upstream dependencies install.
5. Service executable paths point to the binaries actually present.
6. `odoh_servers` and `http3` compatibility errors do not occur.
7. `iptables-legacy` REDIRECT self-test passes.
8. One `PdaNet L4T` menu item appears.
9. One tray icon appears after login.
10. PdaNet WiFi Direct network is joined.
11. Connect succeeds with the default or entered proxy.
12. Browser HTTPS works.
13. `sudo apt update` works.
14. Change Proxy modifies both redsocks and dnscrypt-proxy behavior.
15. Disconnect removes the wrapper NAT chain and stops the two PdaNet proxy services.
16. Reboot leaves no stale connected state and the tray autostarts.
17. `bash uninstall.sh` removes the wrapper without deleting the upstream xsqu1znt installation.
