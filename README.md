# KUP - Automated Cluster Backup for Openshift
Make Openshift 4.x cluster backup easy as drink a Kup of a coffee

## Table of Contents

- [Notes](#notes)
- [How it Works?](#how-it-works)
- [Installation](#installation)
- [Upgrading from Kup 1.0](#upgrading-from-Kup-10)
- [Uninstallation](#uninstallation)

## Notes
This is the 2.0 version of Kup, now it no longer requires to add ssh-key to master nodes.  
As I mainly re-wrote the script and the openshift manifests to make the script less "strictive" I highly recommend to switch at the new version where the pod use node-exporter capabilities to connect into the master nodes and run the backup script.  
To update kup to the new version delete the running `kup-backup` project from the cluster and follow the "Upgrade" guides below
The previous version of the images will be still available but tagged as `xxx_old_notuse`.  

## How it Works
Kup takes the backup of an Openshift cluster by archiving both ETCD and static pod backup.

The Kup backup process can be simplified in this step:

1. The cronjob will schedule a pod on a master node

2. Check the cluster health and "tag" the results in the backup

3. Run the `/usr/local/bin/cluster-backup.sh` script

4. Copy the archive output on a persistent volume specified on the cronjob

### Repository Content
The Repository is formed by this elements:

- `manifest`: directory with all the manifest template needed by the script

- `kup-values.conf`: file with all the values to render in the template

- `kup-render.sh`: script that will render the manifest with the kup-values to create the kup-install.yaml

## Installation

Before starting to render the templates and install the final yaml, it's necessary to create a persistent volume and retrieve the cluster ssh key to access the nodes.

### Add a persistent volume in the cluster
Kup need to use a persistent storage in order to store the Cluster backup in a consistent way.  
Make sure to have the necessary space in the persistent volume to store all the backup you need. From my experience, one Kup backup archive takes from 15 MB to 19 MB of space.

If you need a manifest to create the persistent volume you can use the one below as starting point.

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: kup-backup-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  nfs:
    path: /tmp
    server: 172.17.0.2
  persistentVolumeReclaimPolicy: Retain
```

More infos about provisioning persistent storage are present in the [Persistent Storage pages](https://docs.openshift.com/container-platform/4.5/storage/understanding-persistent-storage.html) of the Openshift docs with all the compatible type of volume in the "Configuring Persistent Volume" section

### Set Kup values
Once both persistent volume and cluster ssh key are ready, it's possible to render the Kup manifests by first editing the `kup-values.conf` and then running the `kup-render.sh` script.

The `kup-values.conf` file has 2 type of values:

- **mandatory**: have value setted to "change-me", must be changed for a correct one to work of Kup.

- **optional**: have a default value that can be changed with something else to customize the default Kup behavior


Mandatory values are:

- `KUP_RENDER_PERSISTENT_VOLUME_NAME`: name of the persistent volume created before

- `KUP_RENDER_OPENSHIFT_VERSION`: version of the cluster, value can be in the format of `4.x` or `v4.x`

If, for example, you have a cluster running with Openshift version `4.5.8`, the correct version of Kup will be `v4.5` or `4.5`

To easily retrieve the Openshift version string to paste in the `kup-values.conf` run the `oc version` command or this snippet on the bastion host:
```bash
[mossicrue@bastion]$ oc version | grep "^Server Version:" | cut -d " " -f 3 | awk -F "." '{print "v"$1"."$2}'
v4.5
```

### Render the manifests
After editing all the values in the kup-values.conf it's possible to render the manifest by running the `kup-render.sh` script.

The script, as for its usage, has 2 optional arguments:

- `-f FILE`: path to Kup "values" file, default is kup-values.conf

- `-m PATH`: path to the directory with the manifest to render, default is ./manifest

A simple command to run for render the manifest can be

```bash
[mossicrue@bastion]$ ./kup-render.sh -f kup-values.conf
```

After the script run, it will generate a new all-in-one manifest called `kup-install.yaml`


### Apply the manifest
Once the `kup-install.yaml` file is generated you can copy it to your bastion server and create all the resources running

```bash
[mossicrue@bastion]$ oc apply -f kup-install.yaml
```

It will create the necessary objects in the `kup-backup` project/namespace.


### Cluster status tag
If the kup-backup service account that run the cronjob has necessary priviliges, the job can also check the health of the cluster and tag the backup with the result of some checks.  


| Health Tag   | Meaning                                                                       |
|--------------|-------------------------------------------------------------------------------|
| sick-masters | one or more master nodes are in "Not Ready" status                            |
| sick-workers | one or more not-master nodes (worker, infra, ecc) are in "Not Ready" status   |
| sick-cluster | one or more master nodes and one or more not-master are in "Not Ready" status |

## Upgrading from Kup 1.0

If you have previously installed the old version of Kup follow these steps to upgrade Kup to the latest version:
- Uninstall Kup from the cluster following the [Uninstallation](#uninstallation) section
- Fresh install Kup with the current version following the [Installation](#installation) section

## Uninstallation

To uninstall Kup from your cluster follow this steps:
- Release the persistent-volume claim from the `kup-backup` project
- Delete the `kup-backup` project from the cluster
- Delete the `kup-backup-pv` persistent volume from the cluster