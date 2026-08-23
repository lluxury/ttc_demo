# ============================================
# Dev 环境：VM + Docker Compose
# ============================================

locals {
  vm_name = "vm-${var.project_name}-${var.environment}"
}

# ============================================
# 网络资源
# ============================================
resource "azurerm_virtual_network" "dev" {
  name                = "vnet-${var.project_name}-${var.environment}"
  address_space       = ["10.0.0.0/16"]
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "dev" {
  name                 = "subnet-${var.project_name}-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.dev.name
  address_prefixes     = ["10.0.1.0/24"]
}

# ============================================
# 安全组
# ============================================
resource "azurerm_network_security_group" "dev" {
  name                = "nsg-${var.project_name}-${var.environment}"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AppPort"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# ============================================
# 公网 IP
# ============================================
resource "azurerm_public_ip" "dev" {
  name                = "pip-${var.project_name}-${var.environment}"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# ============================================
# 网络接口
# ============================================
resource "azurerm_network_interface" "dev" {
  name                = "nic-${var.project_name}-${var.environment}"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.dev.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.dev.id
  }
}

resource "azurerm_network_interface_security_group_association" "dev" {
  network_interface_id      = azurerm_network_interface.dev.id
  network_security_group_id = azurerm_network_security_group.dev.id
}

# ============================================
# 用户托管身份（VM 拉取 ACR 镜像用）
# ============================================
resource "azurerm_user_assigned_identity" "dev_vm" {
  name                = "id-${var.project_name}-${var.environment}-vm"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
}

# 授予 ACR Pull 权限
resource "azurerm_role_assignment" "dev_vm_acr_pull" {
  scope                = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.ContainerRegistry/registries/${var.acr_name}"
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.dev_vm.principal_id
}

data "azurerm_subscription" "current" {}

# ============================================
# VM
# ============================================
resource "azurerm_linux_virtual_machine" "dev" {
  name                = local.vm_name
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  size                = var.vm_size

  network_interface_ids = [azurerm_network_interface.dev.id]

  admin_username = var.vm_admin_username
  admin_password = var.vm_admin_password
  disable_password_authentication = false

  custom_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    project_name                = var.project_name
    acr_login_server            = var.acr_login_server
    acr_name                    = var.acr_name
    log_analytics_workspace_id  = var.log_analytics_workspace_id
    location                    = var.resource_group_location
  }))

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.dev_vm.id]
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }

  depends_on = [
    azurerm_role_assignment.dev_vm_acr_pull
  ]
}