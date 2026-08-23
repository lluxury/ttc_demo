#!/bin/bash
set -e

# 安装 Docker
apt-get update
apt-get install -y docker.io docker-compose git jq
systemctl start docker
systemctl enable docker

# 安装 Azure CLI（用于 ACR 登录）
curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# 安装 Azure CLI ACR 扩展
az extension add --name containerapp --upgrade

# 安装 Docker Compose V2
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# 创建应用目录
mkdir -p /opt/app

# 创建 docker-compose.yml 模板
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
        azure-monitor.workspace-id: ${WORKSPACE_ID}
        azure-monitor.connection-string: ${CONNECTION_STRING}
EOF

# 创建部署脚本
cat > /opt/deploy.sh << 'EOF'
#!/bin/bash
set -e

ACR_LOGIN_SERVER=$1
PROJECT_NAME=$2
IMAGE_TAG=$3
WORKSPACE_ID=$4
CONNECTION_STRING=$5

# 登录 ACR（使用托管身份）
az login --identity --allow-no-subscriptions
az acr login --name ${ACR_LOGIN_SERVER%%\.*}

# 拉取新镜像
docker pull ${ACR_LOGIN_SERVER}/${PROJECT_NAME}:${IMAGE_TAG}

# 更新 docker-compose.yml 中的 Tag
sed -i "s|image: .*|image: ${ACR_LOGIN_SERVER}/${PROJECT_NAME}:${IMAGE_TAG}|g" /opt/app/docker-compose.yml

# 重新部署
cd /opt/app
docker-compose down || true
docker-compose up -d

# 清理旧镜像
docker image prune -f

echo "Deployed ${PROJECT_NAME}:${IMAGE_TAG} to Dev VM"
EOF

chmod +x /opt/deploy.sh

# AWS 对应: user_data.sh.tpl 中的 docker install, aws cli install, deploy script