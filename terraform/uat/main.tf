# ============================================
# UAT 环境：AKS 集群
# 模拟 AWS EKS
# ============================================

# 资源组
resource "azurerm_resource_group" "uat" {
  name     = "rg-${var.project_name}-uat"
  location = var.location
}

# 虚拟网络
resource "azurerm_virtual_network" "uat" {
  name                = "vnet-${var.project_name}-uat"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.uat.location
  resource_group_name = azurerm_resource_group.uat.name
}

resource "azurerm_subnet" "uat" {
  name                 = "subnet-uat"
  resource_group_name  = azurerm_resource_group.uat.name
  virtual_network_name = azurerm_virtual_network.uat.name
  address_prefixes     = ["10.1.1.0/24"]
}

# AKS 集群
# AWS 对应: aws_eks_cluster.uat
resource "azurerm_kubernetes_cluster" "uat" {
  name                = "aks-${var.project_name}-uat"
  location            = azurerm_resource_group.uat.location
  resource_group_name = azurerm_resource_group.uat.name
  dns_prefix          = "${var.project_name}-uat"

  default_node_pool {
    name                = "default"
    node_count          = var.node_count
    vm_size             = "Standard_B2s"  # 对应 t3.medium
    vnet_subnet_id      = azurerm_subnet.uat.id
    enable_auto_scaling = true
    min_count           = var.min_nodes
    max_count           = var.max_nodes
  }

  identity {
    type = "SystemAssigned"
  }

  # 启用容器监控
  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  # AWS 对应: eks_cluster.vpc_config, eks_cluster.logging

  tags = {
    Environment = "uat"
    Project     = var.project_name
  }
}

# AKS 凭证输出
resource "local_file" "kubeconfig_uat" {
  content  = azurerm_kubernetes_cluster.uat.kube_config_raw
  filename = "${path.module}/kubeconfig_uat"
}

# 安装 ArgoCD
# AWS 对应: null_resource.argocd_install
resource "null_resource" "argocd_install_uat" {
  depends_on = [
    azurerm_kubernetes_cluster.uat
  ]

  provisioner "local-exec" {
    command = <<EOF
      az aks get-credentials --name ${azurerm_kubernetes_cluster.uat.name} --resource-group ${azurerm_resource_group.uat.name} --overwrite-existing
      kubectl create namespace argocd || true
      kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
      kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
    EOF
  }
}