# Contributing / community test reports

The most useful contribution right now is a real-device compatibility report.

Please include:

- Switch model / NVIDIA L4T device
- Linux distribution and desktop session
- `uname -r`
- `uname -m`
- Android phone model
- PdaNet+ Android version
- PdaNet proxy IP and port
- whether installation completed
- whether Connect, Disconnect and Change Proxy work
- whether `curl -I https://google.com` and `sudo apt update` work
- whether Full Tunnel was tested
- VPN provider and profile transport when relevant (for example OpenVPN TCP; do not post credentials, private keys or a private provider profile)
- whether Full Tunnel connect/disconnect/reconnect works
- whether saved keyring credentials and Auto-connect Full Tunnel work
- application/game behavior in standard mode and, when tested, through Full Tunnel

Run:

```bash
bash diagnose.sh
```

and include the relevant output with the issue. Review logs before posting them publicly. Do not post passwords, OpenVPN credentials, keyring contents, private keys, private provider profiles, or unrelated personal data.

## Status vocabulary

- **Confirmed**: reproduced on real hardware.
- **Expected**: technically likely, but not yet reproduced.
- **Unsupported**: known not to work or outside the current design.

Please do not turn an Expected configuration into Confirmed without a real test.
