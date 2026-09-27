# Telegram MTProxy One-Click Installation Guide

Author: Sunny8886667

Telegram: [@Bill_999](https://t.me/Bill_999)

Project: [github.com/Sunny8886667/MTProxy](https://github.com/Sunny8886667/MTProxy)

## About

This project is a multilingual one-click installer based on the official Telegram MTProxy source. It targets Debian, Ubuntu, and compatible RHEL-family Linux servers.

The installer detects and installs build dependencies, builds the official source, downloads Telegram's official configuration files, creates a systemd service, and prints a Telegram proxy link.

## Requirements

- Debian 11/12;
- Ubuntu 20.04/22.04/24.04;
- RHEL, CentOS, Rocky, AlmaLinux, or Fedora family systems;
- root access;
- systemd;
- x86_64 is recommended.

The installer does not stop Nginx, Apache, or another process that already uses the client port. It stops with a clear message so you can decide what to do.

## Install

### Clone and run

```bash
git clone https://github.com/Sunny8886667/MTProxy.git
cd MTProxy
sudo bash install.sh
```

### One-line installation

```bash
curl -fsSL https://raw.githubusercontent.com/Sunny8886667/MTProxy/main/install.sh | sudo bash
```

For production servers, download and review the script before executing it.

Test the complete interaction without changing the system:

```bash
bash install.sh --dry-run
```

Dry-run mode does not require root and does not install packages, compile code, write system files, or start services.

## Installer choices

1. Choose 中文, English, or فارسی;
2. See the project introduction, author, and Telegram contact;
3. Enter your own secret or press Enter to generate one;
4. Enter the tag returned by `@MTProxybot`, or press Enter to skip it;
5. Enter the public IP/domain, client port, stats port, and worker count.

Accepted secrets:

- 32 hexadecimal characters for the standard secret;
- 34 hexadecimal characters beginning with `dd` for padded intermediate transport.

Defaults:

- client port: 443;
- local stats port: 8888;
- workers: 1.

## Service commands

```bash
sudo systemctl status mtproxy
sudo journalctl -u mtproxy -f
sudo systemctl restart mtproxy
curl http://127.0.0.1:8888/stats
```

The official proxy configuration is checked daily by a systemd timer:

```bash
sudo systemctl status mtproxy-config-update.timer
sudo systemctl start mtproxy-config-update.service
```

## Configuration paths

```text
/opt/MTProxy/objs/bin/mtproto-proxy
/etc/mtproxy/proxy-secret
/etc/mtproxy/proxy-multi.conf
/etc/mtproxy/mtproxy.env
/etc/systemd/system/mtproxy.service
```

The secret and runtime configuration use restricted permissions. Never commit them to GitHub or post them in a public chat.

## TLS-domain note

The current official MTProxy quick-start does not document a standard TLS-domain binding installation flow. This project therefore does not add unofficial Fake-TLS or `ee` secret configuration.

## Uninstall

```bash
sudo bash uninstall.sh
```

The uninstall script removes the services but keeps the binary and configuration by default, so your secret is not accidentally destroyed. Remove the directories manually after reviewing them.

## Official references

- [TelegramMessenger/MTProxy](https://github.com/TelegramMessenger/MTProxy)
- [Official MTProxy README](https://github.com/TelegramMessenger/MTProxy/blob/master/README.md)
- [Official MTProto transports documentation](https://core.telegram.org/mtproto/mtproto-transports)

