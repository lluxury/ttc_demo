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
  default     = "prod"
}

variable "node_count" {
  description = "AKS 节点数"
  default     = 3
}

variable "node_vm_size" {
  description = "AKS 节点 VM 规格"
  default     = "Standard_D2s_v3"
}

variable "kubernetes_version" {
  description = "Kubernetes 版本"
  default     = "1.28"
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

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  type        = string
}