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
- any applications that fail because they require UDP

Run:

```bash
bash diagnose.sh
```

and include the relevant output with the issue. Do not post passwords, private keys, or unrelated personal data.

## Status vocabulary

- **Confirmed**: reproduced on real hardware.
- **Expected**: technically likely, but not yet reproduced.
- **Unsupported**: known not to work or outside the current design.

Please do not turn an Expected configuration into Confirmed without a real test.
