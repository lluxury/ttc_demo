# ============================================
# 共享资源：ACR + GitHub OIDC 配置
# ============================================

# AWS 对应:
#   - aws_ecr_repository
#   - aws_iam_openid_connect_provider
#   - aws_iam_role.github_actions

# 随机后缀（确保资源名称唯一）
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Azure Container Registry（模拟 AWS ECR）
resource "azurerm_container_registry" "main" {
  name                = "acr${var.project_name}${random_string.suffix.result}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  admin_enabled       = false

  # AWS 对应: aws_ecr_repository.main
}

# GitHub OIDC 配置（Azure AD 应用注册）
# AWS 对应: aws_iam_openid_connect_provider.github
resource "azuread_application" "github_oidc" {
  display_name     = "github-actions-${var.project_name}"
  sign_in_audience = "AzureADMyOrg"
}

resource "azuread_service_principal" "github_oidc" {
  client_id = azuread_application.github_oidc.client_id
}

# OIDC 联合凭证 - 信任 GitHub
# AWS 对应: aws_iam_role.github_actions（信任策略中的 Condition）
resource "azuread_application_federated_identity_credential" "github_main" {
  application_id = azuread_application.github_oidc.id
  display_name   = "github-main"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_organization}/${var.github_repository}:ref:refs/heads/main"
}

resource "azuread_application_federated_identity_credential" "github_develop" {
  application_id = azuread_application.github_oidc.id
  display_name   = "github-develop"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_organization}/${var.github_repository}:ref:refs/heads/develop"
}

resource "azuread_application_federated_identity_credential" "github_hotfix" {
  application_id = azuread_application.github_oidc.id
  display_name   = "github-hotfix"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_organization}/${var.github_repository}:ref:refs/heads/hotfix/*"
}

# AWS 对应: aws_iam_role.github_actions 的权限策略
# 使用 Contributor 角色模拟 AWS 权限
resource "azurerm_role_assignment" "github_oidc" {
  scope                = var.resource_group_scope
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_oidc.object_id
}