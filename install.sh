#!/usr/bin/env bash
# 安装 / 更新 CCFDDL 投稿倒计时小部件
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="${SCRIPT_DIR}/package"
APPLET_ID="com.ccfddl.deadline"
INSTALL_DIR="${HOME}/.local/share/plasma/plasmoids/${APPLET_ID}"

if [[ ! -d "${PACKAGE_DIR}" ]]; then
    echo "[!] 找不到 ${PACKAGE_DIR}" >&2
    exit 1
fi

if [[ -d "${INSTALL_DIR}" ]]; then
    echo "[*] 更新小部件 ${APPLET_ID}"
    kpackagetool6 --type=Plasma/Applet -u "${PACKAGE_DIR}"
else
    echo "[*] 安装小部件 ${APPLET_ID}"
    kpackagetool6 --type=Plasma/Applet -i "${PACKAGE_DIR}"
fi

echo ""
echo "完成。接下来："
echo "  1. 重启 plasmashell 或重新登录，使新代码生效："
echo "       systemctl --user restart plasma-plasmashell"
echo "  2. 在桌面上右键 → 添加小组件 → 搜索「CCFDDL」"
echo "  3. 右键小部件 → 配置会议（默认跟踪 ACL，可添加 SIGIR 等）"

if [[ "${1:-}" == "--restart" ]]; then
    echo ""
    echo "[*] 重启 plasmashell ..."
    systemctl --user restart plasma-plasmashell 2>/dev/null \
        || { kquitapp6 plasmashell 2>/dev/null || true; sleep 2; kstart6 plasmashell >/dev/null 2>&1 & }
    echo "[*] 完成"
fi
