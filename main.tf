# 1. Define the Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"  # or a specific newer version
    }
  }
}

provider "azurerm" {
  features {}
  #resource_provider_registrations = "none"
  skip_provider_registration = true
}

# 2. Reference EXISTING Resource Group (The Sandbox one)
data "azurerm_resource_group" "sandbox_rg" {
  name = "1-a2193887-playground-sandbox" # Change this to the exact name from your portal
}

# 3. Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "stellar-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.sandbox_rg.location
  resource_group_name = data.azurerm_resource_group.sandbox_rg.name
}

# 4. Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "internal"
  resource_group_name  = data.azurerm_resource_group.sandbox_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# 5. Public IP
resource "azurerm_public_ip" "pip" {
  name                = "stellar-ip"
  location            = data.azurerm_resource_group.sandbox_rg.location
  resource_group_name = data.azurerm_resource_group.sandbox_rg.name
  allocation_method   = "Static"
}

# 6. Network Interface
resource "azurerm_network_interface" "nic" {
  name                = "stellar-nic"
  location            = data.azurerm_resource_group.sandbox_rg.location
  resource_group_name = data.azurerm_resource_group.sandbox_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

# 7. Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "stellar-VM-01"
  resource_group_name = data.azurerm_resource_group.sandbox_rg.name
  location            = data.azurerm_resource_group.sandbox_rg.location
  size                = "Standard_B1s"
  admin_username      = "stellar"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_ssh_key {
    username   = "stellar"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDsTV7L917uHim+Uvgj7eo8+UlTfJ6zAYBQ0jHaq4MhAyHxYz24Ml4SCXUEs3cPZUYsLu5GGuTO5kk1uyJGgimszeMT3+mjVJp0ZIGhQR+thTXltMur22ELMPeQZiamerCeEgCDDPeDs53kwOuKViMsUBRPAJ90OzyGDhsVKqLrrBcNQHVZpuz+egdmpT2fSCpGl48mpyk83OIJe8JhHukT9OfTdQSTkTOOcaUmzIDmfHEbUaakjk/uu3V+f9b3tdQ0rdY+n4p4wbDh80WbzUc7GzmQRxP/6ShcMu2Jr8N6KqVW8pcrqbIDGcxU4D5tTCRr5cT1exGLvTYvKygvTmW5xjxQso2ozQRneac3ceg8kmZzye3r34EDvw/DCuZZme98s8FwYR6fC4JHVevLGfeH7ZM9vAIFN05kIN3iNHzxns2hREpy46cV95p5oZwgDr7rkp7N+o7o5UaY5HGVAelGtSj7Csxc9+nUFvBW838K+PdXO/GFKpN/5kOidBMiTt27y/v6z5gQ7CqEsqATDhxDIs7gj08yjU5HEVdNt1KOROiXWiq9FlnG5rPrgmzXFP6btHqAfACth7IDZ+j4mbkYHQbpLz/hbsgzrx6llwFMPo/B8dkWi2FZC5CR6cf2XQWHHWZlTgNdihv7YlEOOtBbMfmd1g23M1nT3bNPU740KQ== your_email@example.com"
    # Ensure you have a local SSH key!
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}