#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

SERVICE_NAME="mtproxy"
INSTALL_DIR="${MTPROXY_INSTALL_DIR:-/opt/MTProxy}"
CONFIG_DIR="${MTPROXY_CONFIG_DIR:-/etc/mtproxy}"

[[ "${EUID}" -eq 0 ]] || { printf 'Run as root: sudo bash uninstall.sh\n' >&2; exit 1; }
command -v systemctl >/dev/null 2>&1 || { printf 'systemd/systemctl is required.\n' >&2; exit 1; }

systemctl disable --now "${SERVICE_NAME}.service" 2>/dev/null || true
systemctl disable --now "${SERVICE_NAME}-config-update.timer" 2>/dev/null || true
rm -f \
    "/etc/systemd/system/${SERVICE_NAME}.service" \
    "/etc/systemd/system/${SERVICE_NAME}-config-update.service" \
    "/etc/systemd/system/${SERVICE_NAME}-config-update.timer" \
    /usr/local/sbin/mtproxy-update-config
systemctl daemon-reload

printf 'MTProxy services removed.\n'
printf 'The following data was kept for safety:\n  %s\n  %s\n' "${INSTALL_DIR}" "${CONFIG_DIR}"
printf 'To remove them permanently after reviewing your data, run:\n'
printf '  sudo rm -rf -- %q %q\n' "${INSTALL_DIR}" "${CONFIG_DIR}"


