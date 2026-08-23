output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "resource_group_id" {
  value = azurerm_resource_group.main.id
}

output "location" {
  value = azurerm_resource_group.main.location
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.main.id
}

output "acr_name" {
  value = azurerm_container_registry.main.name
}

output "acr_login_server" {
  value = azurerm_container_registry.main.login_server
}

output "acr_id" {
  value = azurerm_container_registry.main.id
}

# ============================================
# 以下为敏感值，标记 sensitive = true
# 修复：Output refers to sensitive values 错误
# ============================================
output "tenant_id" {
  value     = var.azure_ad_tenant_id
  sensitive = true
}

output "subscription_id" {
  value     = var.azure_subscription_id
  sensitive = true
}

output "client_id" {
  value     = var.azure_ad_client_id
  sensitive = true
}