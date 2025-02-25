# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

}

# VNET
resource "azurerm_virtual_network" "vnet" {
  name                = "ASE-Project-VNET"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
  depends_on          = [azurerm_resource_group.rg]
}

# Subnets
resource "azurerm_subnet" "subnet1" {
  name                 = "windows-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  depends_on        = [azurerm_virtual_network.vnet]
}

resource "azurerm_subnet" "subnet2" {
  name                 = "linux-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  depends_on         = [azurerm_virtual_network.vnet]
}

# Generate random passwords
resource "random_password" "linux_password" {
  length  = 16
  special = true
}

resource "random_password" "windows_password" {
  length  = 16
  special = true
}

# Key Vault
resource "azurerm_key_vault" "keyvault" {
  name                = "ASE-Project-KV"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "standard"
  tenant_id           = var.tenant_id

  access_policy {
    tenant_id = var.tenant_id
    object_id = var.user_object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge"
    ]
  }

}

# Store credentials in Key Vault
resource "azurerm_key_vault_secret" "linux_password" {
  name         = "linux-vm-password"
  value        = random_password.linux_password.result
  key_vault_id = var.key_vault_id
  depends_on   = [azurerm_key_vault.keyvault]
}

resource "azurerm_key_vault_secret" "windows_password" {
  name         = "windows-vm-password"
  value        = random_password.windows_password.result
  key_vault_id = var.key_vault_id
  depends_on   = [azurerm_key_vault.keyvault]
}

# Create network interfaces
resource "azurerm_network_interface" "linux_nic" {
  name                = "linux-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "windows_nic" {
  name                = "windows-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create Linux VM
resource "azurerm_linux_virtual_machine" "linux_vm" {
  name                            = "linux-vm"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = "Standard_B1s"
  admin_username                  = "adminuser"
  admin_password                  = random_password.linux_password.result
  disable_password_authentication = false
  depends_on                      = [azurerm_network_interface.linux_nic]

  network_interface_ids = [
    azurerm_network_interface.linux_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

# Create Windows VM
resource "azurerm_windows_virtual_machine" "windows_vm" {
  name                = "windows-vm"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  admin_password      = random_password.windows_password.result
    depends_on                      = [azurerm_network_interface.windows_nic]


  network_interface_ids = [
    azurerm_network_interface.windows_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}
