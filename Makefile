.PHONY: help local stop deploy config-check setup

# 默认目标：显示帮助
help:
	@echo ""
	@echo "  项目部署工具"
	@echo ""
	@echo "  make local    本地构建并运行，访问 http://localhost:8080"
	@echo "  make stop     停止本地运行的容器"
	@echo "  make deploy   将整个项目 rsync 到 Lightsail VPS"
	@echo "  make setup    初始化服务器 nginx（首次部署前运行）"
	@echo "  make help     显示此帮助"
	@echo ""

# 本地运行（docker-compose，支持源码热挂载）
local:
	@echo "🐳 启动本地服务（http://localhost:8080）..."
	docker compose up --build

# 停止本地容器
stop:
	@echo "🛑 停止本地服务..."
	docker compose down

# 部署整个项目到 Lightsail
deploy: config-check
	@bash deploy.sh

# 首次部署：在服务器上安装 nginx
setup: config-check
	@source deploy.config && \
	SSH_OPTS="-i $${SSH_KEY_PATH} -o StrictHostKeyChecking=no" && \
	echo "🔧 安装 nginx..." && \
	ssh $$SSH_OPTS "$${SSH_USER}@$${LIGHTSAIL_HOST}" \
	  "sudo apt-get update -qq && sudo apt-get install -y nginx && \
	   sudo mkdir -p $${REMOTE_PATH} && \
	   sudo chown -R $${SSH_USER}:$${SSH_USER} $${REMOTE_PATH}" && \
	echo "✅ 服务器初始化完成，可以运行 make deploy 部署了。"

# 检查配置是否已填写
config-check:
	@if grep -qE "your-key\.pem" deploy.config; then \
		echo "❌ 请先编辑 deploy.config，填写真实的密钥路径（SSH_KEY_PATH）。"; \
		exit 1; \
	fi
