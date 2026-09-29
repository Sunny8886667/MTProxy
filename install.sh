#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# Telegram MTProxy one-click installer.
# Based on the official upstream build/run instructions:
# https://github.com/TelegramMessenger/MTProxy/blob/master/README.md

PROJECT_NAME="Telegram MTProxy One-Click Installer"
PROJECT_URL="https://github.com/Sunny8886667/MTProxy"
AUTHOR_GITHUB="https://github.com/Sunny8886667"
AUTHOR_TELEGRAM="@Bill_999"
UPSTREAM_REPO="https://github.com/TelegramMessenger/MTProxy.git"
PROXY_SECRET_URL="https://core.telegram.org/getProxySecret"
PROXY_CONFIG_URL="https://core.telegram.org/getProxyConfig"

INSTALL_DIR="${MTPROXY_INSTALL_DIR:-/opt/MTProxy}"
CONFIG_DIR="${MTPROXY_CONFIG_DIR:-/etc/mtproxy}"
SERVICE_NAME="mtproxy"
UPSTREAM_REF="${MTPROXY_REF:-master}"
LANGUAGE="${MTPROXY_LANG:-}"
NONINTERACTIVE="${MTPROXY_NONINTERACTIVE:-0}"

TMP_ROOT=""
SECRET="${MTPROXY_SECRET:-}"
CLIENT_SECRET_PREFIX=""
TAG="${MTPROXY_TAG:-}"
PUBLIC_HOST="${MTPROXY_PUBLIC_HOST:-}"
CLIENT_PORT="${MTPROXY_PORT:-443}"
STATS_PORT="${MTPROXY_STATS_PORT:-8888}"
WORKERS="${MTPROXY_WORKERS:-1}"
DRY_RUN="${MTPROXY_DRY_RUN:-0}"

for argument in "$@"; do
    case "${argument}" in
        --dry-run) DRY_RUN="1" ;;
        --help|-h)
            printf 'Usage: sudo bash install.sh [--dry-run]\n'
            printf '  --dry-run  Test the interactive flow without changing the system.\n'
            exit 0
            ;;
        *)
            printf 'Unknown option: %s\n' "${argument}" >&2
            exit 2
            ;;
    esac
done

# A piped one-line install has no interactive terminal. Use safe defaults in
# that mode instead of trying to read prompts from the script stream.
if [[ ! -t 0 || ! -t 1 ]]; then
    NONINTERACTIVE="1"
fi

cleanup() {
    if [[ -n "${TMP_ROOT}" && -d "${TMP_ROOT}" ]]; then
        rm -rf -- "${TMP_ROOT}"
    fi
}
trap cleanup EXIT

die() {
    printf '\n[%s] %s\n' "ERROR" "$*" >&2
    exit 1
}

msg() {
    local key="$1"
    case "${LANGUAGE}:${key}" in
        zh:language_prompt) printf '请选择语言 / Select language / انتخاب زبان [1-3，默认 1]: ' ;;
        zh:invalid_choice) printf '选择无效，请重新输入。' ;;
        zh:home_title) printf 'MTProxy 一键安装程序' ;;
        zh:home_intro) printf '基于 Telegram 官方 MTProxy 源码的自托管代理安装工具。' ;;
        zh:home_features) printf '功能：自动检测环境、编译官方源码、生成或填写 secret、配置 tag、注册 systemd 服务。' ;;
        zh:author) printf '作者：Sunny8886667' ;;
        zh:contact) printf 'Telegram 联系方式：%s' "${AUTHOR_TELEGRAM}" ;;
        zh:repo) printf '项目地址：%s' "${PROJECT_URL}" ;;
        zh:upstream) printf '官方源码：%s' "${UPSTREAM_REPO}" ;;
        zh:official_docs) printf '官方文档：https://github.com/TelegramMessenger/MTProxy/blob/master/README.md' ;;
        zh:not_official) printf '本项目不是 Telegram 官方发布的软件，安装器只负责自动化官方源码的构建和配置。' ;;
        zh:continue) printf '按 Enter 继续，或按 Ctrl+C 退出：' ;;
        zh:checking) printf '正在检测服务器环境...' ;;
        zh:installing_deps) printf '正在安装缺少的系统依赖...' ;;
        zh:deps_ok) printf '系统依赖检查通过。' ;;
        zh:unsupported_os) printf '暂不支持当前系统。建议使用 Debian 11/12 或 Ubuntu 20.04/22.04/24.04。' ;;
        zh:root_required) printf '请使用 root 运行，示例：sudo bash install.sh' ;;
        zh:systemd_required) printf '当前系统没有可用的 systemd/systemctl，无法安装常驻服务。' ;;
        zh:secret_prompt) printf '请输入 MTProxy secret（直接回车自动生成，输入隐藏）： ' ;;
        zh:secret_generated) printf '未填写 secret，已自动生成。' ;;
        zh:secret_invalid) printf 'secret 必须是 32 位十六进制；如果输入 dd+32 位，dd 只用于客户端随机填充。' ;;
        zh:tag_prompt) printf '请输入 @MTProxybot 返回的 tag（没有则直接回车跳过）： ' ;;
        zh:tag_invalid) printf 'tag 必须是 @MTProxybot 返回的 32 位十六进制字符串。' ;;
        zh:host_prompt) printf '请输入服务器公网 IP 或域名（直接回车自动检测）： ' ;;
        zh:host_detected) printf '检测到公网地址：%s' "${PUBLIC_HOST}" ;;
        zh:host_invalid) printf '公网地址包含不支持的字符，请重新输入。' ;;
        zh:port_prompt) printf '客户端端口 [%s]： ' "${CLIENT_PORT}" ;;
        zh:stats_prompt) printf '本地统计端口 [%s]： ' "${STATS_PORT}" ;;
        zh:workers_prompt) printf 'Worker 数量 [%s]： ' "${WORKERS}" ;;
        zh:port_invalid) printf '端口必须是 1 到 65535 之间的数字。' ;;
        zh:workers_invalid) printf 'Worker 数量必须是正整数。' ;;
        zh:port_busy) printf '端口 %s 已被占用，请更换端口或停止占用它的服务。' "${CLIENT_PORT}" ;;
        zh:stats_port_busy) printf '统计端口 %s 已被占用，请更换统计端口或停止占用它的服务。' "${STATS_PORT}" ;;
        zh:building) printf '正在下载并编译 Telegram 官方 MTProxy 源码...' ;;
        zh:configuring) printf '正在下载并校验 Telegram 官方配置...' ;;
        zh:service_starting) printf '正在创建并启动 systemd 服务...' ;;
        zh:service_failed) printf '服务启动失败，请查看：sudo journalctl -u mtproxy -n 100 --no-pager' ;;
        zh:done) printf '安装完成，MTProxy 已启动。' ;;
        zh:link) printf 'Telegram 代理链接：' ;;
        zh:stats) printf '本地统计地址：http://127.0.0.1:%s/stats' "${STATS_PORT}" ;;
        zh:logs) printf '查看日志：sudo journalctl -u mtproxy -f' ;;
        zh:config_file) printf '配置目录：%s' "${CONFIG_DIR}" ;;
        zh:upgrade_note) printf '如需升级官方源码，可重新运行：MTPROXY_UPGRADE=1 sudo -E bash install.sh' ;;
        zh:firewall_note) printf '请确保云厂商安全组和系统防火墙放行客户端端口 %s；统计端口默认仅供本机访问。' "${CLIENT_PORT}" ;;
        zh:dry_run) printf '模拟运行模式：不会安装依赖、编译源码、写入系统目录或启动服务。' ;;
        zh:dry_run_done) printf '模拟运行完成。上面的配置只用于测试交互，没有任何系统改动。' ;;
        en:language_prompt) printf 'Choose language / 选择语言 / انتخاب زبان [1-3, default 1]: ' ;;
        en:invalid_choice) printf 'Invalid choice. Please try again.' ;;
        en:home_title) printf 'MTProxy One-Click Installer' ;;
        en:home_intro) printf 'A self-hosted installer based on the official Telegram MTProxy source.' ;;
        en:home_features) printf 'Features: environment checks, official source build, secret generation/input, tag setup, and systemd service.' ;;
        en:author) printf 'Author: Sunny8886667' ;;
        en:contact) printf 'Telegram contact: %s' "${AUTHOR_TELEGRAM}" ;;
        en:repo) printf 'Project: %s' "${PROJECT_URL}" ;;
        en:upstream) printf 'Official source: %s' "${UPSTREAM_REPO}" ;;
        en:official_docs) printf 'Official docs: https://github.com/TelegramMessenger/MTProxy/blob/master/README.md' ;;
        en:not_official) printf 'This is not Telegram software; the installer automates building and configuring the official source.' ;;
        en:continue) printf 'Press Enter to continue, or Ctrl+C to exit: ' ;;
        en:checking) printf 'Checking the server environment...' ;;
        en:installing_deps) printf 'Installing missing system dependencies...' ;;
        en:deps_ok) printf 'System dependency check passed.' ;;
        en:unsupported_os) printf 'This operating system is not supported yet. Use Debian 11/12 or Ubuntu 20.04/22.04/24.04.' ;;
        en:root_required) printf 'Run as root, for example: sudo bash install.sh' ;;
        en:systemd_required) printf 'systemd/systemctl is not available, so a persistent service cannot be installed.' ;;
        en:secret_prompt) printf 'Enter the MTProxy secret (press Enter to generate one; input hidden): ' ;;
        en:secret_generated) printf 'No secret entered; a new secret was generated.' ;;
        en:secret_invalid) printf 'The secret must be 32 hexadecimal characters; an optional dd+32 form is used only for the client link.' ;;
        en:tag_prompt) printf 'Enter the tag returned by @MTProxybot (press Enter to skip): ' ;;
        en:tag_invalid) printf 'The tag must be the 32-hex-character value returned by @MTProxybot.' ;;
        en:host_prompt) printf 'Enter the public IP or domain (press Enter to detect it): ' ;;
        en:host_detected) printf 'Detected public address: %s' "${PUBLIC_HOST}" ;;
        en:host_invalid) printf 'The public address contains unsupported characters. Try again.' ;;
        en:port_prompt) printf 'Client port [%s]: ' "${CLIENT_PORT}" ;;
        en:stats_prompt) printf 'Local stats port [%s]: ' "${STATS_PORT}" ;;
        en:workers_prompt) printf 'Worker count [%s]: ' "${WORKERS}" ;;
        en:port_invalid) printf 'The port must be a number from 1 to 65535.' ;;
        en:workers_invalid) printf 'Worker count must be a positive integer.' ;;
        en:port_busy) printf 'Port %s is already in use. Choose another port or stop the conflicting service.' "${CLIENT_PORT}" ;;
        en:stats_port_busy) printf 'The stats port %s is already in use. Choose another stats port or stop the conflicting service.' "${STATS_PORT}" ;;
        en:building) printf 'Downloading and building the official Telegram MTProxy source...' ;;
        en:configuring) printf 'Downloading and validating the official Telegram configuration...' ;;
        en:service_starting) printf 'Creating and starting the systemd service...' ;;
        en:service_failed) printf 'The service failed to start. Check: sudo journalctl -u mtproxy -n 100 --no-pager' ;;
        en:done) printf 'Installation complete. MTProxy is running.' ;;
        en:link) printf 'Telegram proxy link:' ;;
        en:stats) printf 'Local stats endpoint: http://127.0.0.1:%s/stats' "${STATS_PORT}" ;;
        en:logs) printf 'View logs: sudo journalctl -u mtproxy -f' ;;
        en:config_file) printf 'Configuration directory: %s' "${CONFIG_DIR}" ;;
        en:upgrade_note) printf 'To upgrade the official source, run: MTPROXY_UPGRADE=1 sudo -E bash install.sh' ;;
        en:firewall_note) printf 'Allow client port %s in your cloud security group and firewall; the stats port is local-only by default.' "${CLIENT_PORT}" ;;
        en:dry_run) printf 'Dry-run mode: no dependencies, source build, system files, or services will be changed.' ;;
        en:dry_run_done) printf 'Dry run complete. The values above were only used to test the interaction; no system changes were made.' ;;
        fa:language_prompt) printf 'زبان را انتخاب کنید / Choose language / 选择语言 [۱ تا ۳، پیش‌فرض ۱]: ' ;;
        fa:invalid_choice) printf 'انتخاب نامعتبر است؛ دوباره تلاش کنید.' ;;
        fa:home_title) printf 'نصب‌کنندهٔ یک‌کلیکی MTProxy' ;;
        fa:home_intro) printf 'ابزار نصب پراکسی خودمیزبان بر پایهٔ کد رسمی Telegram MTProxy.' ;;
        fa:home_features) printf 'امکانات: بررسی محیط، ساخت کد رسمی، تولید یا ورود secret، تنظیم tag و سرویس systemd.' ;;
        fa:author) printf 'نویسنده: Sunny8886667' ;;
        fa:contact) printf 'تماس در Telegram: %s' "${AUTHOR_TELEGRAM}" ;;
        fa:repo) printf 'پروژه: %s' "${PROJECT_URL}" ;;
        fa:upstream) printf 'کد رسمی: %s' "${UPSTREAM_REPO}" ;;
        fa:official_docs) printf 'مستندات رسمی: https://github.com/TelegramMessenger/MTProxy/blob/master/README.md' ;;
        fa:not_official) printf 'این نرم‌افزار متعلق به Telegram نیست؛ این اسکریپت فقط ساخت و پیکربندی کد رسمی را خودکار می‌کند.' ;;
        fa:continue) printf 'برای ادامه Enter و برای خروج Ctrl+C را بزنید: ' ;;
        fa:checking) printf 'در حال بررسی محیط سرور...' ;;
        fa:installing_deps) printf 'در حال نصب وابستگی‌های سیستم...' ;;
        fa:deps_ok) printf 'بررسی وابستگی‌های سیستم موفق بود.' ;;
        fa:unsupported_os) printf 'این سیستم‌عامل هنوز پشتیبانی نمی‌شود. Debian 11/12 یا Ubuntu 20.04/22.04/24.04 استفاده کنید.' ;;
        fa:root_required) printf 'اسکریپت را با root اجرا کنید، مثال: sudo bash install.sh' ;;
        fa:systemd_required) printf 'systemd/systemctl در دسترس نیست و سرویس دائمی نصب نمی‌شود.' ;;
        fa:secret_prompt) printf 'secret مربوط به MTProxy را وارد کنید (Enter برای تولید خودکار؛ ورودی مخفی است): ' ;;
        fa:secret_generated) printf 'secret وارد نشد؛ secret جدید تولید شد.' ;;
        fa:secret_invalid) printf 'secret باید ۳۲ کاراکتر هگزادسیمال باشد؛ قالب dd به‌علاوهٔ ۳۲ کاراکتر فقط برای پیوند سمت کاربر است.' ;;
        fa:tag_prompt) printf 'tag دریافتی از @MTProxybot را وارد کنید (برای رد کردن Enter بزنید): ' ;;
        fa:tag_invalid) printf 'tag باید مقدار ۳۲ کاراکتری هگزادسیمال دریافتی از @MTProxybot باشد.' ;;
        fa:host_prompt) printf 'IP عمومی یا دامنهٔ سرور را وارد کنید (Enter برای تشخیص خودکار): ' ;;
        fa:host_detected) printf 'نشانی عمومی شناسایی شد: %s' "${PUBLIC_HOST}" ;;
        fa:host_invalid) printf 'نشانی عمومی شامل کاراکتر پشتیبانی‌نشده است.' ;;
        fa:port_prompt) printf 'پورت اتصال کاربران [%s]: ' "${CLIENT_PORT}" ;;
        fa:stats_prompt) printf 'پورت آمار محلی [%s]: ' "${STATS_PORT}" ;;
        fa:workers_prompt) printf 'تعداد worker [%s]: ' "${WORKERS}" ;;
        fa:port_invalid) printf 'پورت باید عددی بین ۱ تا ۶۵۵۳۵ باشد.' ;;
        fa:workers_invalid) printf 'تعداد worker باید یک عدد مثبت باشد.' ;;
        fa:port_busy) printf 'پورت %s در حال استفاده است؛ پورت دیگری انتخاب کنید.' "${CLIENT_PORT}" ;;
        fa:stats_port_busy) printf 'پورت آمار %s در حال استفاده است؛ پورت دیگری برای آمار انتخاب کنید.' "${STATS_PORT}" ;;
        fa:building) printf 'در حال دریافت و ساخت کد رسمی Telegram MTProxy...' ;;
        fa:configuring) printf 'در حال دریافت و بررسی پیکربندی رسمی Telegram...' ;;
        fa:service_starting) printf 'در حال ساخت و اجرای سرویس systemd...' ;;
        fa:service_failed) printf 'اجرای سرویس ناموفق بود. بررسی کنید: sudo journalctl -u mtproxy -n 100 --no-pager' ;;
        fa:done) printf 'نصب کامل شد و MTProxy در حال اجراست.' ;;
        fa:link) printf 'پیوند پراکسی Telegram:' ;;
        fa:stats) printf 'نشانی آمار محلی: http://127.0.0.1:%s/stats' "${STATS_PORT}" ;;
        fa:logs) printf 'مشاهدهٔ لاگ: sudo journalctl -u mtproxy -f' ;;
        fa:config_file) printf 'پوشهٔ پیکربندی: %s' "${CONFIG_DIR}" ;;
        fa:upgrade_note) printf 'برای ارتقای کد رسمی اجرا کنید: MTPROXY_UPGRADE=1 sudo -E bash install.sh' ;;
        fa:firewall_note) printf 'پورت %s را در فایروال و security group باز کنید؛ پورت آمار به‌صورت پیش‌فرض فقط محلی است.' "${CLIENT_PORT}" ;;
        fa:dry_run) printf 'حالت آزمایشی: هیچ وابستگی، کد، فایل سیستمی یا سرویسی تغییر نمی‌کند.' ;;
        fa:dry_run_done) printf 'اجرای آزمایشی کامل شد. مقادیر بالا فقط برای تست تعامل بودند و تغییری در سیستم ایجاد نشد.' ;;
        *) printf '%s' "${key}" ;;
    esac
}

choose_language() {
    if [[ -n "${LANGUAGE}" ]]; then
        case "${LANGUAGE,,}" in
            zh|zh-cn|1) LANGUAGE="zh" ;;
            en|en-us|2) LANGUAGE="en" ;;
            fa|fa-ir|3) LANGUAGE="fa" ;;
            *) LANGUAGE="zh" ;;
        esac
        return
    fi

    if [[ "${NONINTERACTIVE}" == "1" ]]; then
        LANGUAGE="zh"
        return
    fi

    while true; do
        printf '\n1) 中文\n2) English\n3) فارسی\n'
        read -r -p "$(msg language_prompt)" choice
        choice="${choice:-1}"
        case "${choice}" in
            1) LANGUAGE="zh"; return ;;
            2) LANGUAGE="en"; return ;;
            3) LANGUAGE="fa"; return ;;
            *) printf '%s\n' "$(msg invalid_choice)" ;;
        esac
    done
}

show_homepage() {
    printf '\n============================================================\n'
    printf '%s\n' "$(msg home_title)"
    printf '============================================================\n'
    printf '%s\n' "$(msg home_intro)"
    printf '%s\n' "$(msg home_features)"
    printf '%s\n' "$(msg author)"
    printf '%s\n' "$(msg contact)"
    printf '%s\n' "$(msg repo)"
    printf '%s\n' "$(msg upstream)"
    printf '%s\n' "$(msg official_docs)"
    printf '%s\n' "$(msg not_official)"
    if [[ "${DRY_RUN}" == "1" ]]; then
        printf '%s\n' "$(msg dry_run)"
    fi
    printf '============================================================\n\n'

    if [[ "${NONINTERACTIVE}" != "1" ]]; then
        read -r -p "$(msg continue)" _
    fi
}

require_root() {
    [[ "${DRY_RUN}" == "1" ]] && return
    [[ "${EUID}" -eq 0 ]] || die "$(msg root_required)"
}

get_os_id() {
    [[ -r /etc/os-release ]] || die "$(msg unsupported_os)"
    OS_ID="$(awk -F= '$1 == "ID" {gsub(/"/, "", $2); print tolower($2)}' /etc/os-release)"
    OS_LIKE="$(awk -F= '$1 == "ID_LIKE" {gsub(/"/, "", $2); print tolower($2)}' /etc/os-release)"
}

install_dependencies() {
    if [[ "${DRY_RUN}" == "1" ]]; then
        printf '%s\n' "DRY-RUN: skip dependency installation and systemd checks."
        return
    fi
    printf '%s\n' "$(msg checking)"
    get_os_id

    if [[ "${OS_ID} ${OS_LIKE}" == *debian* || "${OS_ID} ${OS_LIKE}" == *ubuntu* ]]; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y
        apt-get install -y git curl ca-certificates build-essential libssl-dev zlib1g-dev iproute2 procps openssl util-linux
    elif [[ "${OS_ID} ${OS_LIKE}" == *rhel* || "${OS_ID} ${OS_LIKE}" == *fedora* || "${OS_ID} ${OS_LIKE}" == *centos* || "${OS_ID} ${OS_LIKE}" == *rocky* || "${OS_ID} ${OS_LIKE}" == *almalinux* ]]; then
        if command -v dnf >/dev/null 2>&1; then
            dnf install -y git curl ca-certificates gcc make openssl-devel zlib-devel iproute procps-ng openssl util-linux
        elif command -v yum >/dev/null 2>&1; then
            yum install -y git curl ca-certificates gcc make openssl-devel zlib-devel iproute procps-ng openssl util-linux
        else
            die "$(msg unsupported_os)"
        fi
    else
        printf '%s\n' "$(msg unsupported_os)"
        die "Unsupported distribution: ${OS_ID}"
    fi

    command -v systemctl >/dev/null 2>&1 || die "$(msg systemd_required)"
    for command_name in git curl make cc openssl runuser systemctl ss; do
        command -v "${command_name}" >/dev/null 2>&1 || die "Missing required command: ${command_name}"
    done
    printf '%s\n' "$(msg deps_ok)"
}

validate_number() {
    local value="$1"
    [[ "${value}" =~ ^[0-9]+$ ]] || return 1
    local value10=$((10#${value}))
    (( value10 >= 1 && value10 <= 65535 ))
}

validate_workers() {
    [[ "$1" =~ ^[0-9]+$ ]] || return 1
    local value10=$((10#$1))
    (( value10 >= 1 && value10 <= 128 ))
}

detect_public_host() {
    PUBLIC_HOST="$(curl -4fsS --max-time 8 https://api.ipify.org 2>/dev/null || true)"
    if [[ -z "${PUBLIC_HOST}" ]]; then
        PUBLIC_HOST="$(hostname -I 2>/dev/null | awk '{print $1}')"
    fi
}

ask_settings() {
    if [[ -r "${CONFIG_DIR}/mtproxy.env" ]]; then
        if [[ -z "${SECRET}" ]]; then
            SECRET="$(awk -F= '$1 == "MTPROXY_SECRET" {print substr($0, index($0, "=") + 1); exit}' "${CONFIG_DIR}/mtproxy.env")"
        fi
        if [[ -z "${TAG}" ]]; then
            TAG="$(awk -F= '$1 == "MTPROXY_TAG" {print substr($0, index($0, "=") + 1); exit}' "${CONFIG_DIR}/mtproxy.env")"
        fi
        if [[ -z "${PUBLIC_HOST}" ]]; then
            PUBLIC_HOST="$(awk -F= '$1 == "MTPROXY_PUBLIC_HOST" {print substr($0, index($0, "=") + 1); exit}' "${CONFIG_DIR}/mtproxy.env")"
        fi
        if [[ "${MTPROXY_PORT+x}" != x ]]; then
            CLIENT_PORT="$(awk -F= '$1 == "MTPROXY_PORT" {print substr($0, index($0, "=") + 1); exit}' "${CONFIG_DIR}/mtproxy.env")"
        fi
        if [[ "${MTPROXY_STATS_PORT+x}" != x ]]; then
            STATS_PORT="$(awk -F= '$1 == "MTPROXY_STATS_PORT" {print substr($0, index($0, "=") + 1); exit}' "${CONFIG_DIR}/mtproxy.env")"
        fi
        if [[ "${MTPROXY_WORKERS+x}" != x ]]; then
            WORKERS="$(awk -F= '$1 == "MTPROXY_WORKERS" {print substr($0, index($0, "=") + 1); exit}' "${CONFIG_DIR}/mtproxy.env")"
        fi
    fi

    if [[ -z "${SECRET}" ]]; then
        if [[ "${NONINTERACTIVE}" == "1" ]]; then
            SECRET="$(openssl rand -hex 16)"
            printf '%s\n' "$(msg secret_generated)"
        else
            read -r -s -p "$(msg secret_prompt)" SECRET
            printf '\n'
            if [[ -z "${SECRET}" ]]; then
                SECRET="$(openssl rand -hex 16)"
                printf '%s\n' "$(msg secret_generated)"
            fi
        fi
    fi
    SECRET="${SECRET,,}"
    if [[ "${SECRET}" =~ ^dd[0-9a-f]{32}$ ]]; then
        CLIENT_SECRET_PREFIX="dd"
        SECRET="${SECRET:2}"
    fi
    [[ "${SECRET}" =~ ^[0-9a-f]{32}$ ]] || die "$(msg secret_invalid)"

    if [[ -z "${TAG}" && "${NONINTERACTIVE}" != "1" ]]; then
        read -r -p "$(msg tag_prompt)" TAG
    fi
    if [[ -n "${TAG}" ]]; then
        TAG="${TAG,,}"
        [[ "${TAG}" =~ ^[0-9a-f]{32}$ ]] || die "$(msg tag_invalid)"
    fi

    if [[ -z "${PUBLIC_HOST}" ]]; then
        if [[ "${NONINTERACTIVE}" == "1" ]]; then
            detect_public_host
        else
            detect_public_host
            default_host="${PUBLIC_HOST}"
            read -r -p "$(msg host_prompt)" entered_host
            PUBLIC_HOST="${entered_host:-${default_host}}"
        fi
    fi
    [[ "${PUBLIC_HOST}" =~ ^[A-Za-z0-9._:-]+$ ]] || die "$(msg host_invalid)"
    printf '%s\n' "$(msg host_detected)"

    if [[ "${MTPROXY_PORT+x}" != x && "${NONINTERACTIVE}" != "1" ]]; then
        read -r -p "$(msg port_prompt)" entered_port
        CLIENT_PORT="${entered_port:-${CLIENT_PORT}}"
    fi
    validate_number "${CLIENT_PORT}" || die "$(msg port_invalid)"

    if [[ "${MTPROXY_STATS_PORT+x}" != x && "${NONINTERACTIVE}" != "1" ]]; then
        read -r -p "$(msg stats_prompt)" entered_stats_port
        STATS_PORT="${entered_stats_port:-${STATS_PORT}}"
    fi
    validate_number "${STATS_PORT}" || die "$(msg port_invalid)"

    if [[ "${MTPROXY_WORKERS+x}" != x && "${NONINTERACTIVE}" != "1" ]]; then
        read -r -p "$(msg workers_prompt)" entered_workers
        WORKERS="${entered_workers:-${WORKERS}}"
    fi
    validate_workers "${WORKERS}" || die "$(msg workers_invalid)"
}

check_client_port() {
    [[ "${DRY_RUN}" == "1" ]] && return
    if systemctl is-active --quiet "${SERVICE_NAME}"; then
        return
    fi
    if ss -ltnH 2>/dev/null | awk '{print $4}' | grep -Eq "(^|:)${CLIENT_PORT}$"; then
        die "$(msg port_busy)"
    fi
    if [[ "${STATS_PORT}" != "${CLIENT_PORT}" ]] && ss -ltnH 2>/dev/null | awk '{print $4}' | grep -Eq "(^|:)${STATS_PORT}$"; then
        die "$(msg stats_port_busy)"
    fi
}

ensure_user() {
    [[ "${DRY_RUN}" == "1" ]] && return
    if ! id -u mtproxy >/dev/null 2>&1; then
        useradd --system --home-dir /var/lib/mtproxy --create-home --shell /usr/sbin/nologin --user-group mtproxy
    fi
    install -d -o mtproxy -g mtproxy -m 0750 /var/lib/mtproxy
}

build_mtproxy() {
    if [[ "${DRY_RUN}" == "1" ]]; then
        printf '%s\n' 'DRY-RUN: skip downloading and compiling the official MTProxy source.'
        return
    fi
    if [[ -x "${INSTALL_DIR}/objs/bin/mtproto-proxy" && "${MTPROXY_UPGRADE:-0}" != "1" ]]; then
        printf '%s\n' "MTProxy binary already exists; use MTPROXY_UPGRADE=1 to rebuild from the official source."
        return
    fi
    printf '%s\n' "$(msg building)"
    TMP_ROOT="$(mktemp -d /tmp/mtproxy-installer.XXXXXX)"
    # mktemp creates a root-only directory. The source is cloned and built as
    # mtproxy, so hand ownership of the temporary workspace to that user.
    chown mtproxy "${TMP_ROOT}"
    chmod 0750 "${TMP_ROOT}"
    local source_dir="${TMP_ROOT}/MTProxy"
    runuser -u mtproxy -- git clone --depth=1 --branch "${UPSTREAM_REF}" "${UPSTREAM_REPO}" "${source_dir}"
    if ! runuser -u mtproxy -- make -C "${source_dir}" -j"$(nproc)"; then
        # Newer GCC versions default to -fno-common. Some upstream revisions
        # still contain common symbols, so retry with the compatibility flag.
        printf '%s\n' 'Initial MTProxy build failed; retrying with -fcommon for newer GCC toolchains...'
        runuser -u mtproxy -- make -C "${source_dir}" clean || true
        runuser -u mtproxy -- sed -i 's/^CFLAGS = /CFLAGS = -fcommon /' "${source_dir}/Makefile"
        runuser -u mtproxy -- make -C "${source_dir}" -j"$(nproc)" || die 'MTProxy build failed. Review the compiler output above.'
    fi
    [[ -x "${source_dir}/objs/bin/mtproto-proxy" ]] || die "MTProxy build did not produce the expected binary."

    install -d -o root -g root -m 0755 "${INSTALL_DIR}/objs/bin"
    install -o root -g mtproxy -m 0755 "${source_dir}/objs/bin/mtproto-proxy" "${INSTALL_DIR}/objs/bin/mtproto-proxy.new"
    mv -f "${INSTALL_DIR}/objs/bin/mtproto-proxy.new" "${INSTALL_DIR}/objs/bin/mtproto-proxy"
    runuser -u mtproxy -- git -C "${source_dir}" rev-parse HEAD > "${INSTALL_DIR}/.upstream-commit"
    chown root:mtproxy "${INSTALL_DIR}/.upstream-commit"
    chmod 0640 "${INSTALL_DIR}/.upstream-commit"
}

download_config() {
    if [[ "${DRY_RUN}" == "1" ]]; then
        printf '%s\n' 'DRY-RUN: skip downloading proxy-secret and proxy-multi.conf.'
        return
    fi
    printf '%s\n' "$(msg configuring)"
    install -d -o root -g mtproxy -m 0750 "${CONFIG_DIR}"
    local secret_tmp config_tmp
    secret_tmp="$(mktemp "${CONFIG_DIR}/.proxy-secret.XXXXXX")"
    config_tmp="$(mktemp "${CONFIG_DIR}/.proxy-multi.conf.XXXXXX")"
    trap 'rm -f -- "${secret_tmp}" "${config_tmp}"' RETURN

    curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' --tlsv1.2 \
        --output "${secret_tmp}" "${PROXY_SECRET_URL}"
    curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' --tlsv1.2 \
        --output "${config_tmp}" "${PROXY_CONFIG_URL}"

    [[ "$(wc -c < "${secret_tmp}")" -eq 128 ]] || die "Unexpected proxy-secret size."
    [[ "$(wc -c < "${config_tmp}")" -ge 100 ]] || die "Unexpected proxy-multi.conf size."
    grep -q '^default ' "${config_tmp}" || die "proxy-multi.conf validation failed."
    grep -q '^proxy_for ' "${config_tmp}" || die "proxy-multi.conf validation failed."

    chown root:mtproxy "${secret_tmp}" "${config_tmp}"
    # MTProxy reads the official files again after dropping to its runtime
    # user, so they must remain world-readable like the upstream instructions.
    chmod 0644 "${secret_tmp}" "${config_tmp}"
    mv -f "${secret_tmp}" "${CONFIG_DIR}/proxy-secret"
    mv -f "${config_tmp}" "${CONFIG_DIR}/proxy-multi.conf"
    trap - RETURN
}

write_runtime_config() {
    if [[ "${DRY_RUN}" == "1" ]]; then
        printf '%s\n' 'DRY-RUN: skip writing /etc/mtproxy and the systemd unit.'
        return
    fi
    local tag_args=""
    if [[ -n "${TAG}" ]]; then
        tag_args="-P ${TAG}"
    fi

    umask 077
    cat > "${CONFIG_DIR}/mtproxy.env" <<EOF
MTPROXY_SECRET=${SECRET}
MTPROXY_TAG=${TAG}
MTPROXY_PUBLIC_HOST=${PUBLIC_HOST}
MTPROXY_PORT=${CLIENT_PORT}
MTPROXY_STATS_PORT=${STATS_PORT}
MTPROXY_WORKERS=${WORKERS}
EOF
    chown root:mtproxy "${CONFIG_DIR}/mtproxy.env"
    chmod 0640 "${CONFIG_DIR}/mtproxy.env"

    cat > "/etc/systemd/system/${SERVICE_NAME}.service" <<EOF
[Unit]
Description=Telegram MTProxy
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=${INSTALL_DIR}
EnvironmentFile=${CONFIG_DIR}/mtproxy.env
ExecStart=${INSTALL_DIR}/objs/bin/mtproto-proxy -u nobody -p \${MTPROXY_STATS_PORT} -H \${MTPROXY_PORT} -S \${MTPROXY_SECRET} ${tag_args} --aes-pwd ${CONFIG_DIR}/proxy-secret ${CONFIG_DIR}/proxy-multi.conf -M \${MTPROXY_WORKERS}
Restart=on-failure
RestartSec=5
LimitNOFILE=131072
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
RestrictAddressFamilies=AF_INET AF_INET6
CapabilityBoundingSet=CAP_SETUID CAP_SETGID CAP_NET_BIND_SERVICE
LockPersonality=true
RestrictRealtime=true
NoNewPrivileges=false
UMask=0077

[Install]
WantedBy=multi-user.target
EOF
    chmod 0644 "/etc/systemd/system/${SERVICE_NAME}.service"
}

write_update_service() {
    if [[ "${DRY_RUN}" == "1" ]]; then
        printf '%s\n' 'DRY-RUN: skip installing the daily configuration-update timer.'
        return
    fi
    install -d -o root -g root -m 0755 /usr/local/sbin
    cat > /usr/local/sbin/mtproxy-update-config <<EOF
#!/usr/bin/env bash
set -Eeuo pipefail
CONFIG_DIR="${CONFIG_DIR}"
TMP_DIR="\$(mktemp -d /tmp/mtproxy-config.XXXXXX)"
trap 'rm -rf -- "\${TMP_DIR}"' EXIT
secret="\${TMP_DIR}/proxy-secret"
config="\${TMP_DIR}/proxy-multi.conf"
curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' --tlsv1.2 --output "\${secret}" "${PROXY_SECRET_URL}"
curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' --tlsv1.2 --output "\${config}" "${PROXY_CONFIG_URL}"
test "\$(wc -c < "\${secret}")" -eq 128
test "\$(wc -c < "\${config}")" -ge 100
grep -q '^default ' "\${config}"
grep -q '^proxy_for ' "\${config}"
chown root:mtproxy "\${secret}" "\${config}"
chmod 0644 "\${secret}" "\${config}"
install -o root -g mtproxy -m 0644 "\${secret}" "\${CONFIG_DIR}/proxy-secret.new"
install -o root -g mtproxy -m 0644 "\${config}" "\${CONFIG_DIR}/proxy-multi.conf.new"
if ! cmp -s "\${CONFIG_DIR}/proxy-secret.new" "\${CONFIG_DIR}/proxy-secret" || ! cmp -s "\${CONFIG_DIR}/proxy-multi.conf.new" "\${CONFIG_DIR}/proxy-multi.conf"; then
    mv -f "\${CONFIG_DIR}/proxy-secret.new" "\${CONFIG_DIR}/proxy-secret"
    mv -f "\${CONFIG_DIR}/proxy-multi.conf.new" "\${CONFIG_DIR}/proxy-multi.conf"
    systemctl try-restart ${SERVICE_NAME}.service
else
    rm -f "\${CONFIG_DIR}/proxy-secret.new" "\${CONFIG_DIR}/proxy-multi.conf.new"
fi
EOF
    chmod 0755 /usr/local/sbin/mtproxy-update-config

    cat > "/etc/systemd/system/${SERVICE_NAME}-config-update.service" <<EOF
[Unit]
Description=Update Telegram MTProxy configuration
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/mtproxy-update-config
EOF

    cat > "/etc/systemd/system/${SERVICE_NAME}-config-update.timer" <<EOF
[Unit]
Description=Daily Telegram MTProxy configuration update

[Timer]
OnCalendar=*-*-* 03:15:00
RandomizedDelaySec=30m
Persistent=true

[Install]
WantedBy=timers.target
EOF
    chmod 0644 "/etc/systemd/system/${SERVICE_NAME}-config-update.service" "/etc/systemd/system/${SERVICE_NAME}-config-update.timer"
}

start_services() {
    if [[ "${DRY_RUN}" == "1" ]]; then
        printf '%s\n' 'DRY-RUN: skip enabling and starting mtproxy.service.'
        return
    fi
    printf '%s\n' "$(msg service_starting)"
    systemctl daemon-reload
    systemctl enable --now "${SERVICE_NAME}.service"
    systemctl enable --now "${SERVICE_NAME}-config-update.timer"
    if ! systemctl is-active --quiet "${SERVICE_NAME}.service"; then
        systemctl status "${SERVICE_NAME}.service" --no-pager -l || true
        journalctl -u "${SERVICE_NAME}.service" -n 80 --no-pager || true
        die "$(msg service_failed)"
    fi
}

show_result() {
    local proxy_link="tg://proxy?server=${PUBLIC_HOST}&port=${CLIENT_PORT}&secret=${CLIENT_SECRET_PREFIX}${SECRET}"
    printf '\n============================================================\n'
    printf '%s\n' "$(msg done)"
    printf '%s\n' "$(msg link)"
    printf '%s\n' "${proxy_link}"
    printf '%s\n' "$(msg stats)"
    printf '%s\n' "$(msg logs)"
    printf '%s\n' "$(msg config_file)"
    printf '%s\n' "$(msg firewall_note)"
    printf '%s\n' "$(msg upgrade_note)"
    if [[ "${DRY_RUN}" == "1" ]]; then
        printf '%s\n' "$(msg dry_run_done)"
    fi
    printf '============================================================\n'
}

main() {
    choose_language
    show_homepage
    require_root
    install_dependencies
    ask_settings
    check_client_port
    ensure_user
    build_mtproxy
    download_config
    write_runtime_config
    write_update_service
    start_services
    show_result
}

main "$@"

