# ============================================
# Prod 环境：AKS 集群（高可用配置）
# 模拟 AWS EKS（生产规格）
# ============================================

resource "azurerm_resource_group" "prod" {
  name     = "rg-${var.project_name}-prod"
  location = var.location
}

resource "azurerm_virtual_network" "prod" {
  name                = "vnet-${var.project_name}-prod"
  address_space       = ["10.2.0.0/16"]
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name
}

resource "azurerm_subnet" "prod" {
  name                 = "subnet-prod"
  resource_group_name  = azurerm_resource_group.prod.name
  virtual_network_name = azurerm_virtual_network.prod.name
  address_prefixes     = ["10.2.1.0/24"]
}

# AWS 对应: aws_eks_cluster.prod
resource "azurerm_kubernetes_cluster" "prod" {
  name                = "aks-${var.project_name}-prod"
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name
  dns_prefix          = "${var.project_name}-prod"

  # 生产规格：更大节点
  default_node_pool {
    name                = "default"
    node_count          = var.node_count
    vm_size             = "Standard_D2s_v3"  # 对应 t3.large
    vnet_subnet_id      = azurerm_subnet.prod.id
    enable_auto_scaling = true
    min_count           = var.min_nodes
    max_count           = var.max_nodes
  }

  identity {
    type = "SystemAssigned"
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  # 生产环境关闭公网访问
  # AWS 对应: endpoint_public_access = false
  # 注意：AKS 暂不支持直接关闭公网，可通过网络策略实现

  tags = {
    Environment = "prod"
    Project     = var.project_name
  }
}

resource "local_file" "kubeconfig_prod" {
  content  = azurerm_kubernetes_cluster.prod.kube_config_raw
  filename = "${path.module}/kubeconfig_prod"
}

# 安装 ArgoCD
resource "null_resource" "argocd_install_prod" {
  depends_on = [
    azurerm_kubernetes_cluster.prod
  ]

  provisioner "local-exec" {
    command = <<EOF
      az aks get-credentials --name ${azurerm_kubernetes_cluster.prod.name} --resource-group ${azurerm_resource_group.prod.name} --overwrite-existing
      kubectl create namespace argocd || true
      kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
      kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
    EOF
  }
}

# AWS 对应: aws_eks_cluster.prod + aws_eks_node_group.prod