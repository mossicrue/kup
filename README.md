# KUP - Automated Cluster Backup for Openshift
Make Openshift 4.x cluster backup easy as drink a Kup of a coffee

## How it works?
Kup takes the backup of an Openshift cluster by archiving both ETCD and static pod backup.

The Kup backup process can be simplified in this step:

- Log on the openshift cluster and check master node health

- Run the `/usr/local/bin/cluster-backup.sh` script on a master node

- Copy the archive output on a persistent volume

### Repository Content
The Repository is formed by this elements:

- manifest: directory with all the manifest template needed by the script

- kup-values.conf: file with all the values to render in the template

- kup-render.sh: script that will render the manifest with the kup-values to create the kup-install.yaml

## Getting Started

### Prerequisites
Before starting to render the templates and install the final yaml, it's necessary:
- add a persistent volume
- retrieve the ssh-key to access the cluster as the core user

### Render the Manifest

### Installation
