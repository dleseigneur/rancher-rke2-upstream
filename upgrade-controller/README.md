# System Upgrade Controller
# 

[source RKE2 Automated Upgrade](https://docs.rke2.io/upgrade/automated_upgrade/)

# Objectif
Pouvoir mettre à jour la version de RKE2 de notre cluster de management.

# Principe de fonctionnement
En pré-requis, il nous faudra déployer un `System Upgrade Controller` qui aura pour rôle d'appliquer un `plan` d'upgrade sur les Masters/Workers.

# Déploiement du Controller
Pour déployer l'Upgrade Controller :

 ```shell
 kubectl apply -f system-upgrade-controller.yaml
 ```
 Le pod sera déployé dans son namespace 'system-upgrade', et sera en attente d'un objet de type `plan` qui contiendra le détail des upgrades à réaliser.

# Définition des plans 
Il est préconisé d'avoir 1 plan dédié pour les Masters et un autre pour les Workers.

Parmi les paramètres communs aux 2 plans :
```shell
spec:
  concurrency: 1            # pour définir le nb de noeud à traiter en parallèle
  version: v1.22.10+rke2r2  # pour définir la version Kubernetes cible 
  cordon: true              # pour empêcher le scheduler créer des pods sur le noeud
  drain:
    force: true             # pour forcer l'éviction des pods
```
Paramètres spécifiques au plan 'Agent' :
```shell
  prepare:                  # init-container qui attend la bonne fin de l'upgrade des masters
    args:
    - prepare
    - server-plan
    image: rancher/rke2-upgrade
```

Déploiement des plans définissant les mises à jour à appliquer :
 ```shell
 kubectl apply -f upgrade-plans.yaml
 ```
Ces plans seront détectés par l'`Upgrade Controller` qui créera des `jobs` pour exécuter la mise à jour sur les noeuds.


# Troubleshooting :

- Surveiller les pods qui réalisent la mise à jour, dans le namespace 'system-upgrade'

- Vérifier que les composants de type `job` sont 'complete' dans 'kube-system' :
  - helm-install-*

- Vérifier qu'il n'y a pas de namespaces qui restent en 'Terminating'
  si c'est le cas, faire un 'describe' sur le NS et éventuellement supprimer les 2 objets suivants sous k9s (un message devrait confirmer un blocage sur cet élément):
  - Apiservices/v1beta1.metrics.k8s.io
  - Mutatingwebhookconfigurations/rancher.cattle.io
