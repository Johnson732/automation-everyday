provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "my_ec2" {
  ami           = "ami-0abcdef1234567890" 
  instance_type = "t3.micro"
  key_name      = "myprivkey"             

  vpc_security_group_ids = ["sg-123"]     
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "my_rg" {
  name     = "tf_rg"
  location = "eastus"
}

resource "azurerm_virtual_network" "my_vnet" {
  name                = "tf_vnet"
  address_space       = ["10.0.0.0/16"]
  resource_group_name = azurerm_resource_group.my_rg.name
  location            = azurerm_resource_group.my_rg.location
}

resource "azurerm_subnet" "my_subnet" {
  name                 = "tf_subnet"
  resource_group_name  = azurerm_resource_group.my_rg.name
  virtual_network_name = azurerm_virtual_network.my_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "my_nic" {
  name                = "tf_nic"
  resource_group_name = azurerm_resource_group.my_rg.name
  location            = azurerm_resource_group.my_rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.my_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "my_vm" {
  name                = "tf_az_vm"
  resource_group_name = azurerm_resource_group.my_rg.name
  location            = azurerm_resource_group.my_rg.location
  size                = "Standard_B1s"
  admin_username      = "johnson"
  
  admin_ssh_key {
    username   = "johnson"  
    public_key = file("~/.ssh/id_rsa.pub")  
  }

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
  
  network_interface_ids = [azurerm_network_interface.my_nic.id]
}
