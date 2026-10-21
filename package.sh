#!/usr/bin/env bash
# 打包成可分发的 .plasmoid 文件
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="${SCRIPT_DIR}/package"
OUT_DIR="${SCRIPT_DIR}/dist"
VERSION="$(jq -r '.KPlugin.Version' "${PACKAGE_DIR}/metadata.json" 2>/dev/null || echo 1.0.0)"
OUT_FILE="${OUT_DIR}/ccfddl-deadline-${VERSION}.plasmoid"

command -v zip >/dev/null || { echo "[!] 需要 zip" >&2; exit 1; }

mkdir -p "${OUT_DIR}"
rm -f "${OUT_FILE}"

echo "[*] 打包 ${OUT_FILE}"
(
    cd "${PACKAGE_DIR}"
    zip -q -r -X "${OUT_FILE}" .
)

ls -lh "${OUT_FILE}"
echo ""
echo "安装方法：在桌面上右键 → 添加小组件 → 安装小组件 From Local File，选择上面的 .plasmoid"
