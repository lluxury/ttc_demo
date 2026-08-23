# variables.tf
variable "location" {
  description = "Azure 区域"
  default     = "eastasia"
}

variable "project_name" {
  description = "项目名称"
  default     = "myapp"
}

variable "environment" {
  description = "环境标识"
  default     = "dev"
}

variable "vm_size" {
  description = "VM 实例规格"
  default     = "Standard_B2s"
}

variable "vm_admin_username" {
  description = "VM 管理员用户名"
  default     = "azureuser"
}

variable "vm_admin_password" {
  description = "VM 管理员密码"
  type        = string
  sensitive   = true
}

# 从 common 传入
variable "resource_group_name" {
  description = "资源组名称"
  type        = string
}

variable "resource_group_location" {
  description = "资源组位置"
  type        = string
}

variable "acr_login_server" {
  description = "ACR 登录服务器"
  type        = string
}

variable "acr_name" {
  description = "ACR 名称"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  type        = string
}