data "vsphere_datacenter" "dc" {
    name = var.vsphere-datacenter
}

data "vsphere_datastore" "datastores" {
    for_each = var.vm-datastore
    name = each.value
    datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "clusters" {
    for_each = var.vsphere-cluster
    name = each.value
    datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_distributed_virtual_switch" "dvs" {
  for_each = var.dvs
  name          = each.value
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "networks" {
    for_each = var.dvs
    name = var.vm-network
    datacenter_id = data.vsphere_datacenter.dc.id
    distributed_virtual_switch_uuid = data.vsphere_distributed_virtual_switch.dvs[each.key].id
}

# Create VM Folder
 resource "vsphere_folder" "folder" {
   path          = var.rancher2_nom_cluster
   type          = "vm"
   datacenter_id = data.vsphere_datacenter.dc.id
 }
data "vsphere_virtual_machine" "template" {
    name = var.vm-template-name
    datacenter_id = data.vsphere_datacenter.dc.id
}

# Random ID
resource "random_id" "vm_suffixe" {
 byte_length = 3
}

// # Create first Master
resource "vsphere_virtual_machine" "master-1" {
    name = "${var.vm-prefix-master}-az1-1-${random_id.vm_suffixe.hex}"
    resource_pool_id = data.vsphere_compute_cluster.clusters["az1"].resource_pool_id
    datastore_id = data.vsphere_datastore.datastores["az1"].id
    folder = var.rancher2_nom_cluster

    num_cpus = var.vm-cpu-master
    memory = var.vm-ram-master
    guest_id = var.vm-guest-id
    enable_disk_uuid = true

    network_interface {
        network_id = data.vsphere_network.networks["az1"].id
    }

    dynamic "disk" {
      for_each = data.vsphere_virtual_machine.template.disks
    
      content {
       label       = "disk${disk.value.unit_number}"
       unit_number = disk.value.unit_number
       # Si 3eme disque alors on utilise la taille definie dans le tfvars
       size        =  disk.value.unit_number == 2 ? var.vm-disk-data-size : disk.value.size
       eagerly_scrub    = disk.value.eagerly_scrub
       thin_provisioned = disk.value.thin_provisioned
      }
    }
    clone {
        template_uuid = data.vsphere_virtual_machine.template.id
        customize {
          timeout = 0
          linux_options {
            host_name = "${var.vm-prefix-master}-az1-1-${random_id.vm_suffixe.hex}"
            domain = var.vm-domain-name
          }
          network_interface {}
          #   # DHCP
          #   dns_server_list = var.vm-dns-servers
          #   dns_suffix_list = var.vm-dns-search
        }
    }
    cdrom {
      client_device = true
    }
    connection {
      type = "ssh"
      user = "root"
      host = self.default_ip_address
      private_key = file("./keys/rkeid_rsa")
    }
    provisioner "file" {
      source = "../env/${var.environnement}"
      destination = "/tmp/rke2pe"
     }
    provisioner "file" {
      source = "./install-rke2"
      destination = "/tmp/rke2pe"
     }
    provisioner "remote-exec" {
      inline = [
        "update-ca-certificates",
        "sh /tmp/rke2pe/install-rke2/prepa-env.sh server ${var.environnement}"
      ]
    }
  lifecycle {
    ignore_changes = [ annotation, tags, datastore_id, disk ]
}
  depends_on = [
    vsphere_folder.folder
  ]
}


resource "null_resource" "get-token" {
  provisioner "local-exec" {
    command = "scp -o  StrictHostKeyChecking=no -i ./keys/rkeid_rsa root@${vsphere_virtual_machine.master-1.default_ip_address}:/var/lib/rancher/rke2/server/token ../env/${var.environnement}/token"
  }
  depends_on = [
    vsphere_virtual_machine.master-1
  ]
}

resource "null_resource" "get-kubeconfig" {
  provisioner "local-exec" {
    command = "scp -o  StrictHostKeyChecking=no -i ./keys/rkeid_rsa root@${vsphere_virtual_machine.master-1.default_ip_address}:/etc/rancher/rke2/rke2.yaml ../env/${var.environnement}/"
  }
  depends_on = [
    vsphere_virtual_machine.master-1
  ]
}

// # Create Masters 2 et 3
resource "vsphere_virtual_machine" "master-bis" {
    count = 2
    name = "${var.vm-prefix-master}-az${count.index + 2}-1-${random_id.vm_suffixe.hex}"
    resource_pool_id = data.vsphere_compute_cluster.clusters["az${count.index + 2}"].resource_pool_id
    datastore_id = data.vsphere_datastore.datastores["az${count.index + 2}"].id
    folder = var.rancher2_nom_cluster

    num_cpus = var.vm-cpu-master
    memory = var.vm-ram-master
    guest_id = var.vm-guest-id
    enable_disk_uuid = true

    network_interface {
        network_id = data.vsphere_network.networks["az${count.index + 2}"].id
    }

    dynamic "disk" {
      for_each = data.vsphere_virtual_machine.template.disks
    
      content {
       label       = "disk${disk.value.unit_number}"
       unit_number = disk.value.unit_number
       # Si 3eme disque alors on utilise la taille definie dans le tfvars
       size        =  disk.value.unit_number == 2 ? var.vm-disk-data-size : disk.value.size
       eagerly_scrub    = disk.value.eagerly_scrub
       thin_provisioned = disk.value.thin_provisioned
      }
    }
    clone {
        template_uuid = data.vsphere_virtual_machine.template.id
        customize {
          timeout = 0
          linux_options {
            host_name = "${var.vm-prefix-master}-az${count.index + 2}-1-${random_id.vm_suffixe.hex}"
            domain = var.vm-domain-name
          }
          network_interface {}
          #   # DHCP
          #   dns_server_list = var.vm-dns-servers
          #   dns_suffix_list = var.vm-dns-search
        }
    }
    cdrom {
      client_device = true
    }
    connection {
      type = "ssh"
      user = "root"
      host = self.default_ip_address
      private_key = file("./keys/rkeid_rsa")
    }
    provisioner "file" {
      source = "../env/${var.environnement}"
      destination = "/tmp/rke2pe"
     }
    provisioner "file" {
      source = "./install-rke2"
      destination = "/tmp/rke2pe"
     }
     
    provisioner "file" {
      content     = "server: \"https://${vsphere_virtual_machine.master-1.default_ip_address}:9345\""
      destination = "/tmp/rke2pe/server.yaml"
    }
    provisioner "remote-exec" {
      inline = [
        "update-ca-certificates",
        "cat /tmp/rke2pe/server.yaml >> /tmp/rke2pe/config-master.yaml",
        "sh /tmp/rke2pe/install-rke2/prepa-env.sh master ${var.environnement}"
      ]
    }

  lifecycle {
    ignore_changes = [ annotation, tags, datastore_id, disk ]
}
  depends_on = [
    null_resource.get-token
  ]
}


locals {
  count-vm = transpose({
    for az, nombre in var.worker-count : az  => [
      for n in range(nombre) : "${az}-${n + 1}"
    ]
  })
}
// # Create Workers 
resource "vsphere_virtual_machine" "workers" {
    for_each = local.count-vm
    name = "${var.vm-prefix-worker}-${each.key}-${random_id.vm_suffixe.hex}"
    resource_pool_id = data.vsphere_compute_cluster.clusters[join("",each.value)].resource_pool_id
    datastore_id = data.vsphere_datastore.datastores[join("",each.value)].id
    folder = var.rancher2_nom_cluster

    num_cpus = var.vm-cpu-worker
    memory = var.vm-ram-worker
    guest_id = var.vm-guest-id
    enable_disk_uuid = true

    network_interface {
        network_id = data.vsphere_network.networks[join("",each.value)].id
    }

    dynamic "disk" {
      for_each = data.vsphere_virtual_machine.template.disks
    
      content {
       label       = "disk${disk.value.unit_number}"
       unit_number = disk.value.unit_number
       # Si 3eme disque alors on utilise la taille definie dans le tfvars
       size        =  disk.value.unit_number == 2 ? var.vm-disk-data-size : disk.value.size
       eagerly_scrub    = disk.value.eagerly_scrub
       thin_provisioned = disk.value.thin_provisioned
      }
    }

    clone {
        template_uuid = data.vsphere_virtual_machine.template.id
        customize {
          timeout = 0
          linux_options {
            host_name = "${var.vm-prefix-worker}-${each.key}-${random_id.vm_suffixe.hex}"
            domain = var.vm-domain-name
          }
          network_interface {}
          #   # DHCP
          #   dns_server_list = var.vm-dns-servers
          #   dns_suffix_list = var.vm-dns-search
        }
    }
    cdrom {
      client_device = true
    }
    connection {
      type = "ssh"
      user = "root"
      host = self.default_ip_address
      private_key = file("./keys/rkeid_rsa")
    }
    provisioner "file" {
      source = "../env/${var.environnement}"
      destination = "/tmp/rke2pe"
     }
    provisioner "file" {
      source = "./install-rke2"
      destination = "/tmp/rke2pe"
    }
    provisioner "file" {
      content     = "server: \"https://${vsphere_virtual_machine.master-1.default_ip_address}:9345\""
      destination = "/tmp/rke2pe/server.yaml"
    }
    provisioner "remote-exec" {
      inline = [
        "update-ca-certificates",
        "cat /tmp/rke2pe/server.yaml >> /tmp/rke2pe/config-agent.yaml",
        "sh /tmp/rke2pe/install-rke2/prepa-env.sh agent ${var.environnement}"
      ]
    }
  lifecycle {
    ignore_changes = [ annotation, tags, datastore_id, disk ]
}
  depends_on = [
    null_resource.get-token
  ]
}

