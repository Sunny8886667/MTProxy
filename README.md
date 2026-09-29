# Telegram MTProxy One-Click Installer

基于 Telegram 官方 MTProxy 源码的多语言一键安装工具，支持自动检测环境、自动安装依赖、生成或填写 secret、配置 `@MTProxybot` tag、systemd 守护和官方配置每日更新。

作者：Sunny8886667  ·  Telegram：[@Bill_999](https://t.me/Bill_999)

Languages:

- [中文教程](docs/README.zh-CN.md)
- [English guide](docs/README.en.md)
- [راهنمای فارسی](docs/README.fa.md)

## Quick install

Clone and run:

```bash
git clone https://github.com/Sunny8886667/MTProxy.git
cd MTProxy
sudo bash install.sh
```

The interactive mode asks for a language first, then opens the management menu for installation, uninstall, start, stop, restart, user connection/statistics, logs, and upgrades.

One-command automatic installation:

```bash
curl -fsSL https://raw.githubusercontent.com/Sunny8886667/MTProxy/main/install.sh | tr -d '\r' | sudo bash
```

This uses safe defaults: Chinese, an automatically generated secret, no tag, automatic public IP detection, ports 443/8888, and one worker.

For security, review the script before executing it on a production server.

## Management commands

After cloning the repository, open the management menu with:

```bash
sudo bash install.sh menu
```

You can also run an individual action:

```bash
sudo bash install.sh status
sudo bash install.sh connection
sudo bash install.sh logs
sudo bash install.sh restart
sudo bash install.sh update-config
sudo bash install.sh uninstall
```

The default uninstall removes the systemd service and timer but keeps the program, configuration, and secret. To remove those as well, use `sudo bash mtproxy-install.sh uninstall --purge --yes` after reviewing the command.

The interactive menu can also be opened directly from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/Sunny8886667/MTProxy/main/install.sh | tr -d '\r' | sudo bash -s -- menu
```

## What it installs

- Official source from [TelegramMessenger/MTProxy](https://github.com/TelegramMessenger/MTProxy).
- Official `proxy-secret` and `proxy-multi.conf` from `core.telegram.org`.
- `/opt/MTProxy/objs/bin/mtproto-proxy`.
- `/etc/mtproxy/` with restricted permissions.
- `mtproxy.service` and a daily configuration-update timer.

## Official documentation decision

The current official MTProxy quick-start documents the standard secret, the optional tag from `@MTProxybot`, `getProxySecret`, `getProxyConfig`, and the `tg://proxy` link format. It does not document a standard TLS-domain binding option. This installer therefore does not add unofficial Fake-TLS or `ee` secrets.

Official references:

- [MTProxy upstream README](https://github.com/TelegramMessenger/MTProxy/blob/master/README.md)
- [MTProto transports](https://core.telegram.org/mtproto/mtproto-transports)

## Disclaimer

This repository is an independent installer and is not published by Telegram. Users are responsible for complying with the laws, policies, and network rules applicable to their server and location.

