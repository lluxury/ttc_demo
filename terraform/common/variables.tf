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

variable "github_organization" {
  description = "GitHub 组织名"
  default     = "your-org"
}

variable "github_repository" {
  description = "GitHub 仓库名"
  default     = "your-repo"
}