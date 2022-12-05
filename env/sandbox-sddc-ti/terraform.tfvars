
# Cluster à traiter
rancher2_nom_cluster = "sandbox-sddc-rancher-ti"

environnement = "sandbox-sddc-ti"
## Variables VMs
# terraform.tfvars

# We define how many master nodes
# we want to deploy for _each_ AZ
# master-count default value = 1
master-count = 1
# VM master
vm-prefix-master = "rke2-master"
vm-cpu-master = "AMODIFIER"
vm-ram-master = "AMODIFIER"


# We define how many worker nodes
# we want to deploy for _each_ AZ
# worker-count default value = 1
# Attention, il faut définir la même
# valeur à toutes les AZ
worker-count = {
  az1 = "1"
  az2 = "1"
  az3 = "1"
}

# VM worker
vm-prefix-worker = "rke2-worker"
vm-cpu-worker = "AMODIFIER"
vm-ram-worker = "AMODIFIER"

# Customisation US
vm-domain-name = "AMODIFIER"
vm-disk-data-size = "AMODIFIER"


# VM Common Configuration
vm-template-name = "tsles15sp3-rke2-1.21.7"
vm-guest-id = "sles15_64Guest"
vm-network = "AMODIFIER"
vm-domain = "rke2.local"
vm-dns-search = ["AMODIFIER"]
vm-dns-servers = ["AMODIFIER"]

# vSphere configuration
vsphere-vcenter = "AMODIFIER"
vsphere-user = "AMODIFIER"
vsphere-password = "AMODIFIER"
vsphere-unverified-ssl = "AMODIFIER"
vsphere-datacenter = "AMODIFIER"
vsphere-cluster = {
  az1 = "AMODIFIER"
  az2 = "AMODIFIER"
  az3 = "AMODIFIER"
}

vm-datastore = {
  az1 = "AMODIFIER"
  az2 = "AMODIFIER"
  az3 = "AMODIFIER"
}

dvs = {
  az1 = "AMODIFIER"
  az2 = "AMODIFIER"
  az3 = "AMODIFIER"
}
