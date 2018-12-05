provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
}

locals = {
  identifier = "awx"
}

resource "azurerm_resource_group" "awx" {
  name     = "${local.identifier}-awx"
  location = "${var.location}"
}

resource "azurerm_virtual_network" "awx" {
  name                = "${local.identifier}-vnet"
  resource_group_name = "${azurerm_resource_group.awx.name}"
  location            = "${var.location}"
  address_space       = ["${var.address_space}"]
}

resource "azurerm_subnet" "awx" {
  name                      = "${local.identifier}-subnet"
  resource_group_name       = "${azurerm_resource_group.awx.name}"
  virtual_network_name      = "${azurerm_virtual_network.awx.name}"
  address_prefix            = "${cidrsubnet(var.address_space, 1, 0)}"
}

resource "azurerm_public_ip" "awx" {
  name                = "${local.identifier}-pip"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.awx.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_network_security_group" "awx" {
  name          = "${local.identifier}-nsg"
  location      = "${var.location}"
  resource_group_name = "${azurerm_resource_group.awx.name}"
  
  security_rule {
    name                       = "HTTP"
    description                = "HTTP access to AWX"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    description                = "HTTP access to AWX"
    priority                   = 201
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "awx" {
  name                      = "${local.identifier}"
  location                  = "${var.location}"
  resource_group_name       = "${azurerm_resource_group.awx.name}"
  network_security_group_id = "${azurerm_network_security_group.awx.id}"

  ip_configuration {
    name                          = "${local.identifier}-ipconfig"
    subnet_id                     = "${azurerm_subnet.awx.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.awx.id}"
  }
}

data "template_file" "awxconfig" {
  template = "${file("config.sh")}"

  vars {
    awx_password       = "${var.awx_pass}"
    subscription_id    = "${var.subscription_id}"
    client_id          = "${var.client_id}"
    client_secret      = "${var.client_secret}"
    tenant_id          = "${var.tenant_id}"
    scm_user           = "${var.scm_user}"
    scm_pass           = "${var.scm_pass}"
    # Used to create a domain-based machine credential
    # domain_name        = "${local.domain_to_join}"
    # domain_admin       = "${var.admin_username}"
    # domain_password    = "${var.admin_password}"
  }
}

resource "azurerm_virtual_machine" "awx" {
  name                             = "${local.identifier}"
  location                         = "${var.location}"
  resource_group_name              = "${azurerm_resource_group.awx.name}"
  network_interface_ids            = ["${azurerm_network_interface.awx.id}"]
  vm_size                          = "Standard_D4_v3"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  lifecycle {
    ignore_changes = ["admin_password"]
  }

  storage_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.4"
    version   = "7.4.20180704"
  }

  storage_os_disk {
    name              = "${local.identifier}-osDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${local.identifier}"
    admin_username = "${var.admin_username}"
    admin_password = "${uuid()}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = "${var.public_ssh_key_data}"
    }
  }
}

resource "null_resource" "ansible_provisioner" {
  depends_on = ["azurerm_virtual_machine.awx"]

  connection {
    type        = "ssh"
    host        = "${azurerm_network_interface.awx.private_ip_address}"
    user        = "${var.admin_username}"
    private_key = "${file("private.key")}"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Connection Established'",
    ]
  }

  provisioner "file" {
    source      = "install.sh"
    destination = "/tmp/install.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install.sh",
      "/tmp/install.sh",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "cat > /tmp/config.sh <<EOL\n${data.template_file.awxconfig.rendered}\nEOL",
      "chmod 600 /tmp/config.sh && chmod +x /tmp/config.sh",
      "/tmp/config.sh",
      #
      # Uncomment below to delete the config script when complete.  Remember, it can contain passwords.
      #
      #"rm /tmp/config.sh",
    ]
  }
}