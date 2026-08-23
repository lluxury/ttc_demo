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
# 创建 docker-compose.yml
# ============================================
cat > /opt/app/docker-compose.yml << 'EOF'
version: '3.8'
services:
  app:
    image: ${ACR_LOGIN_SERVER}/${PROJECT_NAME}:${IMAGE_TAG}
    ports:
      - "80:8080"
    restart: always
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

ACR_LOGIN_SERVER=$1
PROJECT_NAME=$2
IMAGE_TAG=$3
LOG_WORKSPACE_ID=$4

# 登录 ACR（使用托管身份）
az login --identity --allow-no-subscriptions
az acr login --name ${ACR_LOGIN_SERVER%%\.*}

# 拉取新镜像
docker pull ${ACR_LOGIN_SERVER}/${PROJECT_NAME}:${IMAGE_TAG}

# 更新 docker-compose.yml
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