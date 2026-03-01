#!/usr/bin/env bash
# ============================================================
# 一键部署脚本 → AWS Lightsail VPS (rsync)
# 使用方式：
#   chmod +x deploy.sh
#   ./deploy.sh          # 部署整个项目到 Lightsail
#   ./deploy.sh local    # 本地 Docker 预览
# 前置要求：
#   - rsync 已安装（macOS 自带）
#   - 已配置 Lightsail SSH 密钥对
#   - 服务器已安装 nginx（运行 make setup 完成初始化）
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/deploy.config"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ 找不到 deploy.config，请先填写配置文件。"
  exit 1
fi

source "$CONFIG_FILE"

MODE="${1:-deploy}"

# ── 工具检查 ─────────────────────────────────────────────────
check_tools() {
  for tool in rsync ssh; do
    if ! command -v "$tool" &>/dev/null; then
      echo "❌ 未找到 $tool，请先安装。"
      exit 1
    fi
  done
}

# ── 本地预览（需要 Docker）────────────────────────────────────
run_local() {
  if ! command -v docker &>/dev/null; then
    echo "❌ 本地预览需要 Docker，请先安装。"
    exit 1
  fi
  echo "🐳 本地构建镜像..."
  docker build -t apps:local "$SCRIPT_DIR"
  echo ""
  echo "✅ 构建完成，启动本地服务..."
  echo "   主入口：http://localhost:8080"
  echo "   数学游戏：http://localhost:8080/math-games/"
  echo "   按 Ctrl+C 停止"
  echo ""
  docker run --rm -p 8080:80 apps:local
}

# ── 部署到 Lightsail ─────────────────────────────────────────
deploy_lightsail() {
  echo "========================================"
  echo "  项目 → Lightsail VPS 部署"
  echo "========================================"
  echo "  目标主机: $LIGHTSAIL_HOST"
  echo "  用户:     $SSH_USER"
  echo "  远端目录: $REMOTE_PATH"
  echo "========================================"
  echo ""

  SSH_OPTS="-i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no -o ConnectTimeout=10"

  # 1. 确保远端目录存在
  echo "📁 确保远端目录存在..."
  ssh $SSH_OPTS "${SSH_USER}@${LIGHTSAIL_HOST}" \
    "sudo mkdir -p ${REMOTE_PATH} && sudo chown -R ${SSH_USER}:${SSH_USER} ${REMOTE_PATH}"

  # 2. 同步项目文件（排除部署脚本和非必要文件）
  echo ""
  echo "📤 同步文件..."
  rsync -avz --delete \
    --exclude 'deploy.sh' \
    --exclude 'deploy.config' \
    --exclude 'docker-compose.yml' \
    --exclude 'Dockerfile' \
    --exclude 'Makefile' \
    --exclude 'nginx.conf' \
    --exclude '.git' \
    --exclude '.DS_Store' \
    --exclude 'REQUIREMENTS.md' \
    --exclude 'CLAUDE.md' \
    -e "ssh ${SSH_OPTS}" \
    "${SCRIPT_DIR}/" \
    "${SSH_USER}@${LIGHTSAIL_HOST}:${REMOTE_PATH}/"

  # 3. 上传并应用 nginx.conf（替换 root 路径为实际部署路径）
  echo ""
  echo "🔧 更新 nginx 配置..."
  sed "s|root /usr/share/nginx/html;|root ${REMOTE_PATH};|g" \
    "${SCRIPT_DIR}/nginx.conf" | \
    ssh $SSH_OPTS "${SSH_USER}@${LIGHTSAIL_HOST}" \
    "sudo tee /etc/nginx/conf.d/default.conf > /dev/null"

  ssh $SSH_OPTS "${SSH_USER}@${LIGHTSAIL_HOST}" \
    "sudo nginx -t && sudo systemctl reload nginx"

  echo ""
  echo "✅ 部署成功！"
  echo "   主入口：http://${LIGHTSAIL_HOST}"
  echo "   数学游戏：http://${LIGHTSAIL_HOST}/math-games/"
}

# ── 入口 ─────────────────────────────────────────────────────
check_tools

if [[ "$MODE" == "local" ]]; then
  run_local
else
  deploy_lightsail
fi
