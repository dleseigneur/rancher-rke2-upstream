# cluster-rke2 upstream pour le rancher-management
# 

[source RKE2](https://docs.rke2.io/install/quickstart/)

# Objectif
Pouvoir provisionner des `VM sur vsphere` et créer un cluster rke2, sans un cluster  management rancher. Ce cluster sera dédié à la solution `cluster management rancher` déployée via chart helm.

# Préparation infrastructure vsphere
## storage policy sur le vcenter 
L'intérêt du storage policy est de pouvoir déclarer 1 seul storageclass, le scale du stockage se fera uniquement via vcenter sans impact sur la storageclass.

- sur le datastore shared storage ajout d'une balise `rke2`
strategie et profile, stockage , créer `rke-storage-policy` 

## Préparation template sles15
[modification template](./templatesles15sp3-rke2.md)

# Organisation du projet terraform
## Répertoire terraform

| `Fichier/Répertoire` | `Description` | 
| :------: |  :------: |
|  `.terrfaform`   | Inititalisation projet terraform commande `terraform init`.<br/>Download modules fichier `versions.tf`<br/> Répertoire dans `.gitignore`  | 
|  `versions.tf`   | Versions minimum pour chaque provider ici<br/> `vsphere`, `random`, `null`  | 
|  `variables.tf`   | Définition du type des variables:<br/>`string`, `integer`, `list`..| 
|  `main.tf`   | définition de toutes les étapes pour: <br/> création VM vsphere<br/>cluster `rke2 1.21.7`|

## Répertoire env
Exemple avec l'environnement Test Intégration `upstream-ti`   
**Important** le nom du répertoire sous `env/upstream-ti` doit être identique à la valeur de la variable `environnement = upstream-ti` dans le fichier `terraform.tfvars.

| `Répertoire` | `Fichiers` | `Description` | 
| :------: |  :------: | :------: |
|  `env`   | **N/A** | centralisation des environnements, backup terraform |
|  `env/upstream-ti`| | |
| | **terraform.tfvars** | variables terraform pour création VM + cluster rke2 |
| | **terrform.tfstate** | **important** permet de garantir la cohérence du cluster TI |
| | **config-agent.yaml** | configuration worker cluster rke2 |
| | **config-server.yaml** | configuration master cluster rke2 |
| | **registries.yaml** | Uniquement si besoin d'autres  resgistries containerd n'existant pas dans `./install-rke2/registries.yaml` |
| | **token** | Uniquement créer et utiliser pour l'initialisation d'un cluster.<br/>Récupération depuis 1 master `/var/lib/rancher/rke2/server/token`<br/>Ce fichier est dans `.gitignore` |

## Répertoire install-rke2
Ce répertoire est poussé par le `provider: local-exec` à la fin du provisionning de chaque VM. Il exécutera le script `prepa-env.sh` pour faire l'installation rke2 en mode `server` pour les masters ou en mode `agent` pour les workers

- **step 1** : changement des valeurs vsphere à partir des valeurs du fichier `terraform.tfstate`
- **step 2** : configuration du systemd `server` ou `agent`
- **step 3** : recopie des fichiers de configuration rke2, registries containerd et `cpi/csi vsphere`
- **step 4** : workaround pour la `cpi/csi vsphere`
- **step 5** : activation, démarrage du cluster rke2 (si 1ére fois initialisation)
- **step 6** : ajout variable dans `.bashrc` pour utiliser les commandes `kubectl, crictl`

| `Fichiers` | `Description` | 
| :------: |  :------: |
|  `prepa-env.sh`   | script de préparation/initialisation cluster rke2  | 
|  `registries.yaml`   | fichier des registries containerd commune pour tous les env | 
|  `rke2-agent.service`<br/>`rke2-agent.env`   | service systemd agent (role worker node)| 
|  `rke2-server.service`<br/>`rke2-server.env`   | service systemd server (role master node)| 
| `vsphere.conf`<br/>`vsphere-cpi-csi-values.yaml` | fichier pour la `cpi/csi` vsphere valorisés par la script à partir du fichier terraform.tfvars de chaque `env`

## keys
contient les clé ssh pour se connecter au VM.
**TODO**: mettre les clé dans un vault

# Deploiement
Exemple avec un environnement `upstream-ti`
**Avant de commencer mettre à jour les fichiers** :
- [terraform.tfvars](./env/upstream-ti/terraform.tfvars)
- [config-server.yaml](./env/upstream-ti/config-server.yaml)
- [config-master.yaml](./env/upstream-ti/config-master.yaml)
- [config-agent.yaml](./env/upstream-ti/config-agent.yaml)
- [registries.yaml](./terraform/install-rke2/registries.yaml)
- [rkeid_rsa](./terraform/keys/rkeid_rsa)
- [rkeid_rsa.pub](./terraform/keys/rkeid_rsa.pub)

```bash
# cd terraform; terraform init
# terraform apply -var-file ../env/upstream-ti/terraform.tfvars -state=../env/upstream-ti/terraform.tfstate -backup="-" -auto-approve
```
## Récupération du KUBECONFIG
Cette partie reste à automatiser.

Une fois le cluster créé, il faut adapter le fichier KUBECONFIG (soit le fichier `rke2.yaml` d'origine).
```bash
sed -i 's/127.0.0.1/ipmaster/' ../env/upstream-ti/rke2.yaml
sed -i 's/default/nomcluster/' ../env/upstream-ti/rke2.yaml
```


# Installation de kube-vip
Réserver une IP dans la plage de service MetalLB pour kube-vip pour chaque cluster qui en a besoin.
Dans IPAM, affecter à cette IP le nom défini dans le paramètre tls-san de la configuration rke2.

Sur son poste de travail, créer des variables d'environnements correspondant aux informations nécessaires

```
export VIP=IP #IP de service pour les controle-plane
export INTERFACE=eth0 #Interface des nodes sur laquelle monter l'IP de service
export KVVERSION=v0.4.0 #version de kube-vip utilisée
```

Créer un alias pour exécuter kube-vip :

```
alias kube-vip="docker run --network host --rm gcr.io/kube-vip/kube-vip:v0.4.1"
```

Générer le manifeste d'installation

```
kube-vip manifest daemonset \
    --interface $INTERFACE \
    --address $VIP \
    --inCluster \
    --taint \
    --controlplane \
    --services \
    --arp \
    --leaderElection > kube-vip-daemonset.yaml

# Remplacer le préfixe de l'image docker (en attendant de rajouter le proxy dans la conf containerd)

sed -i 's/ghcr.io/AMODIFIER_MAREGISTRIE/' kube-vip-daemonset.yaml
```

Déployer kube-vip sur le cluster :
```
kctx upstream-ti
kubectl apply -f https://kube-vip.io/manifests/rbac.yaml #Installation des RBACs

kubectl apply -f kube-vip-daemonset.yaml # Deploiement du daemonset
```

## Déploiement par helm

L'IP De la VIP est à mettre dans le fichier `helm/env/<cluster>/values-kube-vip-chart.yaml`
```
helm upgrade --install kube-vip kube-vip/kube-vip --version 0.4.2 --namespace kube-system -f helm/env/commun/values-kube-vip.yaml -f helm/env/upstream-ti/values-kube-vip-chart.yaml
```

Pour valider, remplacer, dans le fichier kubeconfig du cluster l'ip du master par le nom DNS du tls-san.


## Mise à jour de RKE2

Afin de mettre à jour RKE2, l'article suivant illustre l'utilisation de [System Upgrade Controller](./upgrade-controller/README.md), qui permet une montée de version automatisée grâce au déploiement d'un simple pod supplémentaire.


# Tips
Lorsque l'on retire un cluster de Rancher, il arrive que ce cluster apparaisse toujours à l'état "Unavailable" dans l'UI.
Pour le faire disparaître définitivement, il est nécessaire d'enlever le finalizer sur l'objet correspondant dans le cluster de manager :

```bash
kubectl get clusters.management.cattle.io #pour identifier le clusterID correspondant au cluster à supprimer
kubectl patch clusters.management.cattle.io <mon_cluster_id> -p '{"metadata":{"finalizers":[]}}' --type=merge
```




