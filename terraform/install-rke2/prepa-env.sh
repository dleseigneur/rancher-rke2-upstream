SRV_TYPE=$1
ENV=$2
CONF_DIR="/etc/rancher/rke2"
TMPDIR="/tmp/rke2pe"
TMPDIRINSTALL="/tmp/rke2pe/install-rke2"
FILEVSPHERE="vsphere-cpi-csi-values.yaml"

printf "Step1 : changement valeurs vsphere\n"
# Boucle : rechercher de toutes les valeurs commenençant par "valueterraform."
# dans le fichier  ${TMPDIRINSTALL}/${FILEVSPHERE}
# découpage pour récupérer la clé après "valueterraform." exemple : vsphere-user pour valueterraform.vsphere-user
# lire la valeur de chaque clé vsphere dans terraform.tfvars pour remplacer dans tous les fichiers 
## commençant par vsphere*
for line in $(cat ${TMPDIRINSTALL}/${FILEVSPHERE})
do
  varkeyterraform=$(echo $line|grep -w valueterraform)
  if [ ! -z $varkeyterraform ]
  then
    varkeyvsphere=$(echo $varkeyterraform | cut -d "." -f2)
    valuevsphere=$(grep -w "^$varkeyvsphere" ${TMPDIR}/terraform.tfvars |awk -F"=" '{print $2}')
    sed -i "s/`echo $varkeyterraform`/`echo $valuevsphere`/g" ${TMPDIRINSTALL}/vsphere*
  fi
done

printf "Step2 : preparation systemd rke2\n"
# création du service systemd
mkdir -p $CONF_DIR /usr/local/lib/systemd/system
if [ $SRV_TYPE = "master" ]; then
  cp ${TMPDIRINSTALL}/rke2-server.* /usr/local/lib/systemd/system
else
  cp ${TMPDIRINSTALL}/rke2-$SRV_TYPE.* /usr/local/lib/systemd/system
fi

printf "Step3 : recopie fichiers de conf rke2\n"
# copie des fichiers rke2 dans $CONF_DIR
cp ${TMPDIR}/config-$SRV_TYPE.yaml $CONF_DIR/config.yaml
cp ${TMPDIRINSTALL}/registries.yaml $CONF_DIR/
[[ -f ${TMPDIR}/registries.yaml ]] && cp ${TMPDIR}/registries.yaml $CONF_DIR/
cp ${TMPDIRINSTALL}/vsphere.conf $CONF_DIR/


printf "Step4 : workaround pour la cpi csi vsphere\n"
# copie du fichier vsphere-cpi-csi-values.yaml avec les valeurs de son env
# ce workaround sera pris pour initaliser la cpi/csi au start de rke2 server
if [ $SRV_TYPE != "agent" ]; then
  mkdir -p /var/lib/rancher/rke2/server/manifests
  cp ${TMPDIRINSTALL}/vsphere-cpi-csi-values.yaml /var/lib/rancher/rke2/server/manifests/
fi

printf "Step5 : activation et démarrage rke2 service\n"
# enable + start du service systemd rke2
# systemctl enable rke2-$SRV_TYPE.service
# systemctl start rke2-$SRV_TYPE.service
# en cas de créationd e master, rétulisation des fichiers de type server pour éviter duplication des fichiers
if [ $SRV_TYPE = "master" ]; then
  systemctl enable rke2-server.service
  systemctl start rke2-server.service
else
  systemctl enable rke2-$SRV_TYPE.service
  systemctl start rke2-$SRV_TYPE.service    
fi

printf "Step6 : ajout variables bashrc\n"
# mise à jour des variables dans .bashrc pour utiliser les commandes crictl, kubectl apporter par rancher.
# KUBECONFIG pour accès au cluster rke2
if ! grep rke2 $HOME/.bashrc
then
  echo "export CRI_CONFIG_FILE=/var/lib/rancher/rke2/agent/etc/crictl.yaml" >>$HOME/.bashrc 
  echo "export KUBECONFIG=/etc/rancher/rke2/rke2.yaml">>$HOME/.bashrc 
  echo "export PATH=$PATH:/var/lib/rancher/rke2/bin">>$HOME/.bashrc
fi  