variable "location" {
  type = string
  default = "south india"
}
variable "vm_name" {
  type = string
  default = "vm02"
}
variable "resource_group_name" {
  type = string
  default = "Learning"
}
variable "vnetRGroup" {
  type = string
}
variable "admin_username" {
  type = string
  default = "winadmin"
}
variable "vm_sku" {
  type = string
  default = "2016-Datacenter"
}
variable "admin_password" {
  type = string
}
variable "vm_size" {
  type = string
  default = "Standard_DS1_v2"
}
variable "os_data_disk_size_in_gb" {
  type = number
  default = 127
}
variable "data_disks" {
  type = list
  default = [60]
}
variable "boot_diag_storage_account" {
  type = string
  default = null
}
variable "vnet_name" {
  type = string
  default = "vnet02"
}
variable "subnet_name" {
  type = string
  default = "subnet02"
}
variable "availability_set" {
  type = string
  default = null
}
variable "identity_id" {
  type = list
  default = []
}
variable "identity" {
  type = string
  default = "no"
}
variable "client_id" {
  type = string
}
variable "client_secret" {
  type = string
}
variable "subscription_id" {
  type = string
}
variable "tenant_id" {
  type = string
}
locals {

}

provider "azurerm" {

	 client_id = var.client_id
	 client_secret = var.client_secret
	 subscription_id = var.subscription_id
	 tenant_id = var.tenant_id
	 features {}
}
terraform {
  backend "azurerm" {
    resource_group_name  = "32943"
    storage_account_name = "cloudlegonewstorage"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
    access_key = "y3yRwsDZoqoz20V6ZlRN3ImBzWXu6BuyUovv13cyfJQKMhtJC2QPa/FxNKTtVDMTwBbbsq9cws2c6U8V7//2oQ=="
    sas_token  = "sp=r&st=2021-04-28T11:52:24Z&se=2021-04-28T19:52:24Z&spr=https&sv=2020-02-10&sr=c&sig=47BDPYHa23pM76hMM5pv0Znam7WHDJasF2RYpJOslpU%3D"
  }
}
data "azurerm_subnet" "vmSubnet" {
  name = var.subnet_name
  resource_group_name = var.vnetRGroup
  virtual_network_name = var.vnet_name
}
data "azurerm_storage_account" "bootDiag" {
  name = var.boot_diag_storage_account
  resource_group_name = var.resource_group_name
}
resource "azurerm_network_interface" "nic01" {
  location = var.location
  name = join("_",[var.vm_name,"nic"])
  resource_group_name = var.resource_group_name
  ip_configuration {
    name = join("_",[var.vm_name,"ip"])
    subnet_id = data.azurerm_subnet.vmSubnet.id
    private_ip_address_allocation = "dynamic"
  }
}
resource "azurerm_virtual_machine" "mvm01" {
  name = var.vm_name
  location = var.location
  resource_group_name = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.nic01.id]
  vm_size = var.vm_size
  availability_set_id = var.availability_set
  os_profile_windows_config {

  }
  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer = "WindowsServer"
    sku = var.vm_sku
    version = "latest"
  }
  storage_os_disk {
    create_option = "FromImage"
    name = join("_",[var.vm_name,"osDisk"])
    disk_size_gb = var.os_data_disk_size_in_gb
  }
  dynamic "storage_data_disk" {
    for_each = [for d in var.data_disks :{
      diskname = join("_",[var.vm_name,"datadisk",index(var.data_disks,d )])
      disklun = index(var.data_disks,d )
      disksizegb = d
      createoption = "Empty"
    }]
    content {
      create_option = storage_data_disk.value.createoption
      lun = storage_data_disk.value.disklun
      name = storage_data_disk.value.diskname
      disk_size_gb = storage_data_disk.value.disksizegb
    }
  }
  os_profile {
    admin_username = var.admin_username
    admin_password = var.admin_password
    computer_name = var.vm_name
  }
  identity {
    type = length(regexall("yes",var.identity )) > 0 ? "UserAssigned":null
  }
  boot_diagnostics {
    enabled = var.boot_diag_storage_account == null ? false:true
    storage_uri = var.boot_diag_storage_account == null ? null:data.azurerm_storage_account.bootDiag.primary_blob_endpoint
  }
}
