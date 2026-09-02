#!/usr/bin/env bash
# ============================================================
# myTV SUPER EPG 一键部署 (curl | bash)
#
# 用法 (无参数 -> 交互式向导: 依次选择 端口/是否需要认证/用户名/密码):
#   bash -c "$(curl -sSL https://raw.githubusercontent.com/soandso888/kkkk/main/quick_start.sh)"
#
# 用法 (带参数 -> 非交互, 顺序: 端口 用户名 密码):
#   curl -sSL https://raw.githubusercontent.com/soandso888/kkkk/main/quick_start.sh | bash -s -- 8080 admin mypass
#   不想启用认证: 用户名传 none
#   curl -sSL https://raw.githubusercontent.com/soandso888/kkkk/main/quick_start.sh | bash -s -- 8080 none
#
# 原理: 从 GitHub Release 下载 epg-bundle.tar.gz -> 解包 -> 运行包内 install.sh
# ============================================================
set -euo pipefail

REPO="soandso888/kkkk"
# 防护: 未生成时 REPO 以 '_' 开头 -> 提示先运行 make_quick_start.sh
# (不能用 == 字面比较, 否则 sed 会把检查条件里的占位符也替换掉)
if [ "${REPO:0:1}" = "_" ]; then
  echo "错误: 此脚本未配置 GitHub 仓库, 请先运行 make_quick_start.sh <owner>/<repo> [备份包名]" >&2
  exit 1
fi

# 备份包下载地址: 默认从仓库根目录 (main 分支) 的直链拉取
# 可用环境变量覆盖: EPG_BUNDLE_URL (自建镜像/测试/Release asset)
BUNDLE_FILENAME="epg-bundle-20260902.tar.gz"
DEFAULT_URL="https://raw.githubusercontent.com/${REPO}/refs/heads/main/${BUNDLE_FILENAME}"
BUNDLE_URL="${EPG_BUNDLE_URL:-$DEFAULT_URL}"

# 安全: 默认只允许 https; 本地测试可用 EPG_ALLOW_INSECURE=1 放行
case "$BUNDLE_URL" in
  https://*) : ;;
  *)
    if [ "${EPG_ALLOW_INSECURE:-0}" != "1" ]; then
      echo "错误: 只允许 https 下载地址 (本地测试可设 EPG_ALLOW_INSECURE=1)" >&2
      exit 1
    fi
    ;;
esac

if [ "$(id -u)" -ne 0 ]; then echo "错误: 请用 root 运行 (sudo)" >&2; exit 1; fi
if ! command -v tar >/dev/null 2>&1; then echo "错误: 未找到 tar" >&2; exit 1; fi

# 下载工具: 优先 curl, 其次 wget, 都没有则自动安装
DL=""
if command -v curl >/dev/null 2>&1; then DL="curl"
elif command -v wget >/dev/null 2>&1; then DL="wget"
else
  echo "== 未找到 curl/wget, 尝试自动安装... =="
  if command -v apt-get >/dev/null 2>&1; then apt-get update -y && apt-get install -y curl
  elif command -v dnf >/dev/null 2>&1; then dnf install -y curl
  elif command -v yum >/dev/null 2>&1; then yum install -y curl
  elif command -v apk >/dev/null 2>&1; then apk add --no-cache curl
  fi
  if command -v curl >/dev/null 2>&1; then DL="curl"
  else
    echo "错误: 无法自动安装 curl, 请先手动安装 curl 或 wget 再重试" >&2
    exit 1
  fi
fi
echo "== 使用 $DL 下载 =="

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "== [1/3] 下载备份包: $BUNDLE_URL =="
if [ "$DL" = "curl" ]; then
  curl -sSL --fail --connect-timeout 20 --retry 2 -o "$TMP/epg-bundle.tar.gz" "$BUNDLE_URL"
else
  wget -q --timeout=20 --tries=2 -O "$TMP/epg-bundle.tar.gz" "$BUNDLE_URL"
fi
ls -lh "$TMP/epg-bundle.tar.gz"

echo "== [2/3] 解包 =="
tar xzf "$TMP/epg-bundle.tar.gz" -C "$TMP"
INST=$(find "$TMP" -maxdepth 3 -name install.sh | head -1)
if [ -z "$INST" ]; then echo "错误: 包内未找到 install.sh" >&2; exit 1; fi
echo "  ok  $(basename "$(dirname "$INST")")"

echo "== [3/3] 开始部署 (参数透传, 无参数则进入交互向导) =="
cd "$(dirname "$INST")"
bash ./install.sh "$@"
