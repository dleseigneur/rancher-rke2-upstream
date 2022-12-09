
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
vm-cpu-master = "2"
vm-ram-master = "8192"


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
vm-cpu-worker = "4"
vm-ram-worker = "16384"

# Customisation US
vm-domain-name = "MYDOMAIN"
vm-disk-data-size = "200"


# VM Common Configuration
vm-template-name = "tsles15sp3-rke2-1.21.7"
vm-guest-id = "sles15_64Guest"
vm-network = "seg-applis-2600"
vm-domain = "rke2.local"
vm-dns-search = ["MYDOMAIN1.fr", "MYDOMAIN2.fr", "MYDOMAIN1.fr"]
vm-dns-servers = ["MYIP1", "MYIP2"]

# vSphere configuration
vsphere-vcenter = "MYVCENTER"
vsphere-user = "MYUSER"
vsphere-password = "MYPASSWORD"
vsphere-unverified-ssl = "true"
vsphere-datacenter = "TZ-SB-WLD01"
vsphere-cluster = {
  az1 = "CL_TZ_SB_WLD01_01"
  az2 = "CL_TZ_SB_WLD01_01"
  az3 = "CL_TZ_SB_WLD01_01"
}

vm-datastore = {
  az1 = "DS_TZ_SB_vSAN_WLD01_01"
  az2 = "DS_TZ_SB_vSAN_WLD01_02"
  az3 = "DS_TZ_SB_vSAN_WLD01_03"
}

dvs = {
  az1 = "DVS_TZ_SB_WLD01_01"
  az2 = "DVS_TZ_SB_WLD01_02"
  az3 = "DVS_TZ_SB_WLD01_03"
}
