# ============================================
# UAT 环境：AKS 集群
# ============================================

# ============================================
# AKS 集群
# ============================================
resource "azurerm_kubernetes_cluster" "uat" {
  name                = "aks-${var.project_name}-${var.environment}"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.project_name}-${var.environment}"

  default_node_pool {
    name                = "default"
    node_count          = var.node_count
    vm_size             = var.node_vm_size
    vnet_subnet_id      = azurerm_subnet.uat.id
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

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# ============================================
# AKS 子网
# ============================================
resource "azurerm_virtual_network" "uat" {
  name                = "vnet-${var.project_name}-${var.environment}"
  address_space       = ["10.1.0.0/16"]
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "uat" {
  name                 = "subnet-${var.project_name}-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.uat.name
  address_prefixes     = ["10.1.1.0/24"]
}

# ============================================
# 保存 kubeconfig
# ============================================
resource "local_file" "kubeconfig_uat" {
  content  = azurerm_kubernetes_cluster.uat.kube_config_raw
  filename = "${path.module}/kubeconfig_uat"
}

# ============================================
# 安装 ArgoCD
# ============================================
resource "null_resource" "argocd_install_uat" {
  depends_on = [
    azurerm_kubernetes_cluster.uat
  ]

  provisioner "local-exec" {
    command = <<EOF
      echo "等待 AKS 集群就绪..."
      az aks get-credentials --name ${azurerm_kubernetes_cluster.uat.name} --resource-group ${var.resource_group_name} --overwrite-existing
      
      echo "创建 argocd 命名空间..."
      kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
      
      echo "安装 ArgoCD..."
      kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
      
      echo "等待 ArgoCD Server 就绪..."
      kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
      
      echo "ArgoCD 安装完成！"
    EOF
  }
}

# ============================================
# 输出 ArgoCD 初始密码
# ============================================
resource "null_resource" "argocd_password_uat" {
  depends_on = [
    null_resource.argocd_install_uat
  ]

  provisioner "local-exec" {
    command = <<EOF
      echo "===== ArgoCD 初始密码 ====="
      kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
      echo ""
      echo "==========================="
    EOF
  }
}