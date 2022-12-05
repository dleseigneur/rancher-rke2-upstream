# vsphere
provider "vsphere" {
    user           = var.vsphere-user
    password       = var.vsphere-password
    vsphere_server = var.vsphere-vcenter

    # If you have a self-signed cert
    allow_unverified_ssl = true
}

