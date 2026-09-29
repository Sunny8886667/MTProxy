# Telegram MTProxy One-Click Installer

基于 Telegram 官方 MTProxy 源码的多语言一键安装工具，支持自动检测环境、自动安装依赖、生成或填写 secret、配置 `@MTProxybot` tag、systemd 守护和官方配置每日更新。

作者：Sunny8886667  ·  Telegram：[@Bill_999](https://t.me/Bill_999)

Languages:

- [中文教程](docs/README.zh-CN.md)
- [English guide](docs/README.en.md)
- [راهنمای فارسی](docs/README.fa.md)

## Quick install

Interactive installation after cloning:

```bash
git clone https://github.com/Sunny8886667/MTProxy.git
cd MTProxy
sudo bash install.sh
```

Download and run interactively:

```bash
curl -fsSL https://raw.githubusercontent.com/Sunny8886667/MTProxy/main/install.sh -o mtproxy-install.sh
sudo bash mtproxy-install.sh
```

Piping directly to `sudo bash` is also supported, but it intentionally uses non-interactive safe defaults.

For security, review the script before executing it on a production server.

Test the complete interactive flow without changing the system:

```bash
bash install.sh --dry-run
```

Dry-run mode does not require root and does not install packages, compile code, write system files, or start services.

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

