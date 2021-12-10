#!/bin/bash
# FILE: kup-render.sh
# AUTHOR: Simone Mossi
# PURPOSE: Script that take the backup of an openshift 4.x cluster through cron jobs

# VARIABLES
# KUP_VALUES_PATH: path to the kup "values" file where all the configuration is stored
KUP_VALUES_PATH="kup-values.conf"
KUP_MANIFESTS_PATH="manifest"
KUP_INSTALL_PATH="kup-install.yaml"

kup_usage() {
  cat << EOF

Kup - Automated ETCD Cluster Backup for Openshift

Usage: kup-render.sh -f <file> [-m <path>]

Options:
-f <file>  - path to Kup "values" file where store configuration data, optional
-m <path>  - path to the directory with all the manifest to render, default is ./manifest

See more at https://github.com/mossicrue/kup

EOF
}

# Parse passed options
while getopts :f:m:h OPTION; do
  case "$OPTION" in
    h)
      kup_usage
      exit 0;;
    f)
      echo -e "Kup values file path: $OPTARG"
      KUP_VALUES_PATH=$OPTARG;;
    m)
      echo -e "Kup manifest directory: $OPTARG"
      KUP_MANIFESTS_PATH=$OPTARG;;
    \?)
      echo -e "Invalid option: -$OPTARG"
      f_usage
      exit 1;;
    :)
      echo -e "Missing argument!"
      f_usage
      exit 1;;
  esac
done

# Main function
if [[ ! -f "$KUP_VALUES_PATH" ]]
then
  echo -n "ERROR: File $KUP_VALUES_PATH not found. Exiting"
  exit 10
fi

# check if manifest directory exist
if [[ ! -d "$KUP_MANIFESTS_PATH" ]]
then
  echo -n "ERROR: Path $KUP_MANIFESTS_PATH not found. Exiting"
  exit 11
fi

# check if manifests are present
MANIFEST_NUMBER=$(ls -1 $KUP_MANIFESTS_PATH | wc -l)
if [[ $MANIFEST_NUMBER -eq 0 ]]
then
  echo -e "ERROR: no manifest seems to be present in the $KUP_MANIFESTS_PATH"
fi

# import all the variables from the kup-values.conf file
source $KUP_VALUES_PATH

# check if ssh key exists and get its content
if [[ ! -f "$KUP_RENDER_CLUSTER_SSH_KEY_PATH" ]]
then
  echo -e "ERROR: ssh key $KUP_RENDER_CLUSTER_SSH_KEY_PATH not found. Exiting"
  exit 20
fi
# make it base64 and save in KUP_RENDER_CLUSTER_SSH_KEY
KUP_RENDER_CLUSTER_SSH_KEY=$(cat $KUP_RENDER_CLUSTER_SSH_KEY_PATH | base64 -w 0 2>/dev/null)

# clean kup-install file
echo "" > $KUP_INSTALL_PATH

# loop all the manifest and render values in ./kup-install.yaml
for KUP_MANIFEST in ${KUP_MANIFESTS_PATH}/*
do
  echo -e "INFO: Rendering manifest $KUP_MANIFEST"
  # check that the manifest isn't empty
  if [[ ! -s "$KUP_MANIFEST" ]]
  then
    echo -e "WARNING: $KUP_MANIFEST is empty. Is it ok?"
    continue
  fi
  # load manifest content
  KUP_MANIFEST_CONTENT=$(cat $KUP_MANIFEST 2>/dev/null)
  # add yaml separator
  echo "---" >> $KUP_INSTALL_PATH
  # render the value in the installation file
  eval "echo -e \"$KUP_MANIFEST_CONTENT\"" >> $KUP_INSTALL_PATH
done
# output how to do the things
echo -e "\nKup is ready to install on your cluster:"
echo -e "  - Copy $KUP_INSTALL_PATH manifest on your bastion host"
echo -e "  - Run: oc apply -f $KUP_INSTALL_PATH\n"
