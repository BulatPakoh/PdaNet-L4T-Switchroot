# Attribution

## xsqu1znt/PdaNetClientCLI-Linux

PdaNet L4T depends on the public GitHub project:

- Project: `xsqu1znt/PdaNetClientCLI-Linux`
- Tested commit: `f20ae0e679f26d1703f6a99ffc1978fc7c7dd84f`

The upstream project supplies the PdaNet Linux Wi-Fi/USB client, including the redsocks and dnscrypt-proxy integration that this wrapper relies on.

PdaNet L4T adds a legacy-L4T routing compatibility layer, configurable proxy handling, installation fixes for the tested Switchroot Noble environment, a system-tray frontend, and an optional OpenVPN TCP Full Tunnel integration.

At the time this package was prepared, no license file was visible in the upstream repository root. Therefore this repository does not include copies of upstream source files and does not claim to relicense upstream work. The installer downloads upstream directly from its original repository.

## OpenVPN and VPN providers

The optional Full Tunnel uses the system OpenVPN package. OpenVPN is third-party software and is not vendored by this repository.

VPN providers are also third parties. Proton VPN Free was used for the confirmed provider test, but Proton is not bundled, required by name, or affiliated with this project.

## PdaNet+

PdaNet+ is third-party software. This project is not affiliated with its developer. Users must obtain and use PdaNet+ under its own terms.
