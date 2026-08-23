# ============================================
# Dev 环境：Azure VM + Docker Compose
# 模拟 AWS EC2 + Docker Compose
# ============================================

# 资源组（如果不在 common 中创建）
resource "azurerm_resource_group" "dev" {
  name     = "rg-${var.project_name}-dev"
  location = var.location
}

# 虚拟网络和子网
resource "azurerm_virtual_network" "dev" {
  name                = "vnet-${var.project_name}-dev"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name
}

resource "azurerm_subnet" "dev" {
  name                 = "subnet-dev"
  resource_group_name  = azurerm_resource_group.dev.name
  virtual_network_name = azurerm_virtual_network.dev.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 安全组
# AWS 对应: aws_security_group.dev
resource "azurerm_network_security_group" "dev" {
  name                = "nsg-${var.project_name}-dev"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name

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

  # AWS 对应: 安全组入站规则
}

# 公网 IP
resource "azurerm_public_ip" "dev" {
  name                = "pip-${var.project_name}-dev"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name
  allocation_method   = "Static"
  sku                 = "Standard"

  # AWS 对应: aws_eip.dev
}

# 网络接口
resource "azurerm_network_interface" "dev" {
  name                = "nic-${var.project_name}-dev"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.dev.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.dev.id
  }
}

# 将安全组绑定到网卡
resource "azurerm_network_interface_security_group_association" "dev" {
  network_interface_id      = azurerm_network_interface.dev.id
  network_security_group_id = azurerm_network_security_group.dev.id
}

# Azure VM（模拟 AWS EC2）
# AWS 对应: aws_instance.dev
resource "azurerm_linux_virtual_machine" "dev" {
  name                = "vm-${var.project_name}-dev"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name
  size                = "Standard_B2s"  # 对应 t3.medium

  network_interface_ids = [azurerm_network_interface.dev.id]

  admin_username = "azureuser"
  admin_password = var.vm_password

  custom_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    project_name    = var.project_name
    acr_name        = var.acr_name
    acr_login_server = var.acr_login_server
    location        = var.location
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

  # AWS 对应: 用户数据（User Data）
}

# VM 托管身份（模拟 AWS IAM Role）
# AWS 对应: aws_iam_role.ec2
resource "azurerm_user_assigned_identity" "dev_vm" {
  name                = "id-${var.project_name}-dev-vm"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name
}

# 授予 ACR 拉取权限
resource "azurerm_role_assignment" "dev_vm_acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.dev_vm.principal_id
}

# 将托管身份分配给 VM
resource "azurerm_virtual_machine_extension" "dev_identity" {
  name                 = "msi-extension"
  virtual_machine_id   = azurerm_linux_virtual_machine.dev.id
  publisher            = "Microsoft.ManagedIdentity"
  type                 = "ManagedIdentityExtensionForLinux"
  type_handler_version = "1.0"

  settings = jsonencode({
    "port" : 50342
  })
}

# AWS 对应: aws_eip.dev（已在公网 IP 中实现）