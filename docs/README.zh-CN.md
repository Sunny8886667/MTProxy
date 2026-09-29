# Telegram MTProxy 一键安装教程

作者：Sunny8886667

Telegram：[@Bill_999](https://t.me/Bill_999)

项目地址：[github.com/Sunny8886667/MTProxy](https://github.com/Sunny8886667/MTProxy)

## 项目介绍

这是一个基于 Telegram 官方 MTProxy 源码的多语言一键安装工具，适用于 Debian、Ubuntu 以及兼容的 RHEL 系 Linux 服务器。

脚本会自动检测并安装构建依赖，编译官方源码，下载 Telegram 官方配置，创建 systemd 服务，并输出可以直接导入 Telegram 的代理链接。

## 系统要求

- Debian 11/12；
- Ubuntu 20.04/22.04/24.04；
- RHEL、CentOS、Rocky、AlmaLinux 或 Fedora 系统；
- root 权限；
- systemd；
- 建议使用 x86_64 服务器。

脚本不会自动停止 Nginx、Apache 或其他占用端口的服务。如果客户端端口已被占用，安装会停止并提示你处理。

## 安装

### 方式一：克隆后安装

```bash
git clone https://github.com/Sunny8886667/MTProxy.git
cd MTProxy
sudo bash install.sh
```

### 方式二：一行命令安装

```bash
curl -fsSL https://raw.githubusercontent.com/Sunny8886667/MTProxy/main/install.sh | sudo bash
```

这条命令会自动使用中文、自动生成 secret、不设置 tag、自动检测公网 IP、使用 443/8888 端口和 1 个 worker。

如果需要显示交互选项，请使用下载后执行的方式：

```bash
curl -fsSL https://raw.githubusercontent.com/Sunny8886667/MTProxy/main/install.sh -o mtproxy-install.sh && sudo bash mtproxy-install.sh
```

生产服务器建议先下载并审查脚本，再执行。

只测试交互、不修改系统：

```bash
bash install.sh --dry-run
```

模拟模式不会安装依赖、编译源码、写入系统目录或启动服务。

## 安装过程中的选项

1. 选择中文、English 或 فارسی；
2. 显示项目介绍、作者和 Telegram 联系方式；
3. 输入自己的 secret，或直接回车自动生成；
4. 输入 `@MTProxybot` 返回的 tag，直接回车可以跳过；
5. 输入公网 IP/域名、客户端端口、统计端口和 Worker 数量。

secret 支持：

- 32 位十六进制标准 secret；
- 也可以输入以 `dd` 开头的 34 位 padded secret；脚本会去掉 `dd` 启动服务，并在客户端链接中保留它。

`@MTProxybot` 返回的 tag 必须是 32 位十六进制字符串。

默认值：

- 客户端端口：443；
- 本地统计端口：8888；
- Worker 数量：1。

## 安装后的常用命令

```bash
sudo systemctl status mtproxy
sudo journalctl -u mtproxy -f
sudo systemctl restart mtproxy
curl http://127.0.0.1:8888/stats
```

官方配置会通过每日 systemd timer 自动检查更新：

```bash
sudo systemctl status mtproxy-config-update.timer
sudo systemctl start mtproxy-config-update.service
```

## 配置文件

```text
/opt/MTProxy/objs/bin/mtproto-proxy
/etc/mtproxy/proxy-secret
/etc/mtproxy/proxy-multi.conf
/etc/mtproxy/mtproxy.env
/etc/systemd/system/mtproxy.service
```

secret 文件和运行配置使用受限权限保存，不应上传到 GitHub 或发送到公开聊天中。

## TLS 域名说明

Telegram 官方当前 MTProxy 快速开始文档没有提供标准的 TLS 域名绑定安装流程。因此本项目不加入未经官方文档确认的 Fake-TLS 或 `ee` secret 配置，避免把第三方方案误认为官方功能。

## 卸载

```bash
sudo bash uninstall.sh
```

卸载脚本默认只删除服务，保留程序和配置，避免误删 secret。确认不再需要后，再按照脚本提示手动删除目录。

## 官方参考

- [TelegramMessenger/MTProxy 官方仓库](https://github.com/TelegramMessenger/MTProxy)
- [官方 MTProxy README](https://github.com/TelegramMessenger/MTProxy/blob/master/README.md)
- [官方 MTProto transports 文档](https://core.telegram.org/mtproto/mtproto-transports)

