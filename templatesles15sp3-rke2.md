# Template linux sles15sp3 pour rke2 version 1.21.7

## Renommage du template sles15sp3 dans les vcenters 
nouveau nom **tsles15sp3-rke2-1.21.7** dans un dossier templates

## Préparation rke2
### récupération de la version rke2
[Télécharger la bonne version rke2 pour linux](https://github.com/rancher/rke2/releases/tag/v1.21.7%2Brke2r1)

## Intervention sur le template
tranformer le template en VM
Ajouter un Disque 3 de 200Go en mode Thin
Démarrer la VM

### recopie le binaire rke2 
```bash
# scp postelocal:/rke2 tsles15sp3-rke2.1.12.7:/usr/local/bin/
# ssh tsles15sp3-rke2.1.12.7 -c "chmode +x /usr/local/bin/
```
### modification paramètres système
```bash
# sysctl vm.max_map_count=262145
```
# Copie de la clé SSH
Copier le fichier ./keys/rkeid_rsa.pub en /root/.ssh/authorized_keys

# Ajout des AC 
Depuis un poste de travail linux :

```bash
# openssl x509 -in /usr/local/share/ca-certificates/MYCERT -text > MYAC.crt
# scp -i keys/rkeid_rsa MYAC.crt root@10.xx.xx.xx:/etc/pki/trust/anchors/
# ssh -i keys/rkeid_rsa root@10.xx.xx.xx
# update-ca-certificates
```

# Resize du vg rootvg
```bash
pvcreate /dev/sdc
vgextend rootvg /dev/sdc
lvextend -l +100%FREE /dev/rootvg/root
xfs_growfs /
```

# Invalider le SWAP
Mettre en commentaire la ligne concernant le SWAP dans le fichier /etc/fstab
### modification Bug wicked
Il faut supprimer les informations wicked pour garantir le dhcp avec un identifiant unique pour le DHCP
```bash
# rm /var/lib/wicked/*
```

### Finalisation
Arrêt de la VM et remise en template.


