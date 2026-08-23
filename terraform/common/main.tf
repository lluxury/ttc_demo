# ============================================
# 资源组（共享）
# ============================================
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
}

# ============================================
# Log Analytics Workspace（供 VM 和 AKS 共用）
# ============================================
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = 1
}

# ============================================
# ACR（镜像仓库）
# ============================================
resource "random_string" "acr_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_container_registry" "main" {
  name                = "acr${var.project_name}${var.environment}${random_string.acr_suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Premium"                     # 保留策略需要 Premium SKU
  admin_enabled       = false
  retention_policy_in_days = 30                      # 自动清理未标记镜像
}

# ============================================
# 注意：AD 应用注册已手动创建，此处不管理
# 参考: GitHub Secrets 中的 AZURE_CLIENT_ID
# ============================================