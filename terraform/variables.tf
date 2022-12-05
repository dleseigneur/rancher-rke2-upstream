# variables.tf
# Declare all the variables needed

variable "rancher2_nom_cluster" {}

variable "environnement" {}
# Customisation US
variable "vm-domain-name" {
    type = string
}
variable "vm-disk-data-size" {
    type = number
}
variable "vsphere-user" {
    type = string
}
variable "vsphere-password" {
    type = string
}
variable "vsphere-vcenter" {
    type = string
}
variable "vsphere-unverified-ssl" {
    type = string
}
variable "vsphere-datacenter" {
    type = string
}
variable "vsphere-cluster" {
    type = map
}
variable "master-count" {
    type = number
    description = "Number of Master VM's"
    default     =  1
}
variable "worker-count" {
    type = map
    description = "Number of Worker VM's"
}

variable "vm-datastore" {
    type = map
}
variable "dvs" {
    type = map
}
variable "vm-network" {
    type = string
}
variable "vm-cpu-master" {
    type = string
    default = "1"
}
variable "vm-ram-master" {
    type = string
}
variable "vm-cpu-worker" {
    type = string
    default = "1"
}
variable "vm-ram-worker" {
    type = string
}
variable "vm-prefix-master" {
    type = string
}
variable "vm-prefix-worker" {
    type = string
}
variable "vm-guest-id" {
    type = string
}
variable "vm-template-name" {
    type = string
}
variable "vm-domain" {
    type = string
}
variable "vm-dns-servers" {
    type = list
}
variable "vm-dns-search" {
    type = list
}
