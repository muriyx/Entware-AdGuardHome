# Entware AdGuard Home

Unofficial [Entware](https://entware.net/) package repository for
[AdGuard Home](https://github.com/AdguardTeam/AdGuardHome).

This project exists to provide more frequent AdGuard Home updates for Entware
users. The package in the main Entware repository can lag behind upstream
releases, so this repository publishes an `adguardhome` package that tracks the
official AdGuard Home releases more closely.

## Supported Platform

Currently published packages target:

- `aarch64-3.10`

Use this repository only on Entware installations with the matching
architecture.

Check your Entware architecture with:

```sh
opkg print-architecture
```

## Installation

Add this package feed to `opkg`:

```sh
echo "src/gz adguardhome https://muriyx.github.io/Entware-AdGuardHome/aarch64-3.10" >> /opt/etc/opkg/adguardhome.conf
opkg update
opkg install adguardhome
```

## Notes

- This is an unofficial repository and is not maintained by the AdGuard or
  Entware teams.
- The package is built from the official AdGuard Home source release.
- The repository is intended for users who want newer AdGuard Home versions on
  Entware-based systems.

## Links

- [AdGuard Home](https://github.com/AdguardTeam/AdGuardHome)
- [AdGuard Home website](https://adguard.com/en/adguard-home/overview.html)
- [Entware](https://entware.net/)
- [Entware packages](https://bin.entware.net/)

## License

Repository scripts and packaging files are licensed under the MIT License. See
[LICENSE](LICENSE).

AdGuard Home is licensed by its upstream authors under GPL-3.0. See the
official [AdGuard Home repository](https://github.com/AdguardTeam/AdGuardHome)
for upstream source code and license information.
