# variables.tf
variable "location" {
  description = "Azure 区域"
  default     = "eastasia"
}

variable "environment" {
  description = "环境标识（dev/stg/prod）"
  default     = "dev"
}

variable "project_name" {
  description = "项目名称"
  default     = "myapp"
}

variable "environment" {
  description = "环境标识"
  default     = "dev"
}

variable "azure_ad_client_id" {
  description = "手动在 Portal 创建的 Azure AD 应用注册的客户端 ID"
  type        = string
  sensitive   = true
}

variable "azure_ad_tenant_id" {
  description = "Azure AD 租户 ID"
  type        = string
  sensitive   = true
}

variable "azure_subscription_id" {
  description = "Azure 订阅 ID"
  type        = string
  sensitive   = true
}