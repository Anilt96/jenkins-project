terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=2.99.0"
    }
  }
}
provider "azurerm" {
features {}
    client_id       = "0a6a9a90-b571-4a22-9e8d-0c7047c040bf"
    client_secret   = "GVg8Q~D7Esbv-pMxo6GaA1RWBevJwUvL2svFjaV6"
    subscription_id = "f3e3cbaa-fa0e-44ba-b842-a744442c2291"
    tenant_id       = "500ae089-9386-4d37-b04c-8ddd1119491d"
}


resource "azurerm_resource_group" "main1" {
    name     = "resources1"
    location = "South India"
}

resource "azurerm_virtual_network" "main1" {
    name                 = "network1"
    address_space        = ["10.0.0.0/16"]
    location             = "South India"
    resource_group_name  = azurerm_resource_group.main1.name
}

resource "azurerm_subnet" "subnet1" {
  name                 = "internal1"
  resource_group_name  = azurerm_resource_group.main1.name
  virtual_network_name = azurerm_virtual_network.main1.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "nic1" {
  name                = "nic1"
  location            = azurerm_resource_group.main1.location
  resource_group_name = azurerm_resource_group.main1.name

  ip_configuration {
    name                          = "internal1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "main1" {
  name                = "main1"
  resource_group_name = azurerm_resource_group.main1.name
  location            = azurerm_resource_group.main1.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password = "Azure@123"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.nic1.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_subnet" "internal2" {
    name                 = "interna2"
    resource_group_name  = azurerm_resource_group.main1.name
    virtual_network_name = azurerm_virtual_network.main1.name
    address_prefixes       = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "main1" {
    name             = "sg1"
    location         = "South India"
    resource_group_name = azurerm_resource_group.main1.name

    security_rule {
        name                        = "HTTP"
        priority                    = 100
        direction                   = "Inbound"
        access                      = "Allow"
        protocol                    = "Tcp"
        source_port_range           = "*"
        destination_port_range      = "8080"
        source_address_prefix       = "*"
        destination_address_prefix  = "*"
    }
    security_rule {
        name                        = "SSH"
        priority                    = 101
        direction                   = "Inbound"
        access                      = "Allow"
        protocol                    = "Tcp"
        source_port_range           = "*"
        destination_port_range      = "22"
        source_address_prefix       = "*"
        destination_address_prefix  = "*"
    }

}

resource "azurerm_network_interface" "main2" {
    name                = "nic2"
    location            = "South India"
    resource_group_name = azurerm_resource_group.main1.name
    ip_configuration {
        name                       = "testconfiguration2"
        subnet_id                  =  azurerm_subnet.internal2.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.main1.id
    }
}

resource "azurerm_network_interface_security_group_association" "main1" {
    network_interface_id            = azurerm_network_interface.main2.id
    network_security_group_id       = azurerm_network_security_group.main1.id
}

resource "azurerm_public_ip" "main1" {
    name                    = "ip"
    location                = "South India"
    resource_group_name     = azurerm_resource_group.main1.name
    allocation_method       = "Dynamic"
    domain_name_label       = "jenkins1"
}

resource "azurerm_virtual_machine" "main2" {
    name                              = "vm2"
    location                          = azurerm_resource_group.main1.location
    resource_group_name               = azurerm_resource_group.main1.name
    network_interface_ids             = [azurerm_network_interface.main2.id]
    vm_size                           = "Standard_B2ms"

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }
    storage_os_disk {
        name          = "myosdisk2"
        caching       = "ReadWrite"
        create_option = "FromImage"
        managed_disk_type = "Standard_LRS"
    }
    os_profile {
        computer_name    = "jenkinsvm"
        admin_username   = "adminuser2"
        admin_password   = "admin@1234"
    }
    os_profile_linux_config {
        disable_password_authentication = false
    }

    

}
