#!/bin/bash
set -e

# ============================================
# 安装 Docker
# ============================================
apt-get update
apt-get install -y docker.io docker-compose git jq curl
systemctl start docker
systemctl enable docker

# ============================================
# 安装 Azure CLI
# ============================================
curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# ============================================
# 安装 Docker Compose V2
# ============================================
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# ============================================
# 创建应用目录
# ============================================
mkdir -p /opt/app

# ============================================
# 创建 .env 文件
# ============================================
cat > /opt/app/.env << EOF
ACR_LOGIN_SERVER=${acr_login_server}
PROJECT_NAME=${project_name}
IMAGE_TAG=latest
LOG_WORKSPACE_ID=${log_analytics_workspace_id}
EOF

# ============================================
# 创建 docker-compose.yml（使用 env_file）
# ============================================
cat > /opt/app/docker-compose.yml << 'EOF'
version: '3.8'
services:
  app:
    image: ${ACR_LOGIN_SERVER}/${PROJECT_NAME}:${IMAGE_TAG}
    ports:
      - "80:8080"
    restart: always
    env_file:
      - .env
    environment:
      - SPRING_PROFILES_ACTIVE=dev
    logging:
      driver: "azure-monitor"
      options:
        azure-monitor.workspace-id: ${LOG_WORKSPACE_ID}
EOF

# ============================================
# 创建部署脚本
# ============================================
cat > /opt/deploy.sh << 'EOF'
#!/bin/bash
set -e

# 加载环境变量
source /opt/app/.env

# 如果传入了 IMAGE_TAG，更新 .env
if [ -n "$1" ]; then
  IMAGE_TAG=$1
  sed -i "s/^IMAGE_TAG=.*/IMAGE_TAG=$IMAGE_TAG/" /opt/app/.env
fi

# 重新加载 .env
source /opt/app/.env

# 登录 ACR（使用托管身份）
az login --identity --allow-no-subscriptions
az acr login --name ${ACR_LOGIN_SERVER%%\.*}

# 拉取新镜像
docker pull ${ACR_LOGIN_SERVER}/${PROJECT_NAME}:${IMAGE_TAG}

# 更新 docker-compose.yml 中的 image 行
cd /opt/app
sed -i "s|image: .*|image: ${ACR_LOGIN_SERVER}/${PROJECT_NAME}:${IMAGE_TAG}|g" docker-compose.yml

# 重新部署
docker-compose down || true
docker-compose up -d

# 清理旧镜像
docker image prune -f

echo "Deployed ${PROJECT_NAME}:${IMAGE_TAG} to Dev VM"
EOF

chmod +x /opt/deploy.sh

echo "Dev VM setup completed."