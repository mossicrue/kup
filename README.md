# KUP - Automated Cluster Backup for Openshift
Make Openshift 4.x cluster backup easy as drink a Kup of a coffee
NOTE: This is the 2.0 version of Kup, now it no longer requires to add ssh-key to master nodes.

## How it works?
Kup takes the backup of an Openshift cluster by archiving both ETCD and static pod backup.

The Kup backup process can be simplified in this step:

1. The cronjob will schedule a pod on a master node

2. Run the `/usr/local/bin/cluster-backup.sh` script

3. Copy the archive output on a persistent volume specified on the cronjob

### Repository Content
The Repository is formed by this elements:

- `manifest`: directory with all the manifest template needed by the script

- `kup-values.conf`: file with all the values to render in the template

- `kup-render.sh`: script that will render the manifest with the kup-values to create the kup-install.yaml

## Kup Installation

Before starting to render the templates and install the final yaml, it's necessary to create a persistent volume and retrieve the cluster ssh key to access the nodes.

### Add a persistent volume in the cluster
Kup need to use a persistent storage in order to store the Cluster backup in a consistent way.  
Make sure to have the necessary space in the persistent volume to store all the backup you need. From my experience, one Kup backup archive takes from 15 MB to 19 MB of space.

If you need a manifest to create the persistent volume you can use the one below as starting point.

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv0001
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


Mandatory values are 2, and they are:

- `KUP_RENDER_PERSISTENT_VOLUME_NAME`: name of the persistent volume created before

- `KUP_RENDER_OPENSHIFT_VERSION`: version of the cluster, value can be in the format of `4.x` or `v4.x`

If, for example, you have a cluster running with Openshift version `4.5.8`, the correct version of Kup will be `v4.5` or `4.5`

To easily retrieve the Openshift version string to paste in the `kup-values.conf` run this command on the bastion host:
```bash
[mossicrue@bastion]$ oc version | grep "^Server Version:" | cut -d " " -f 3 | awk -F "." '{print "v"$1"."$2}'
v4.5
```

### Render the manifests
After editing all the values in the kup-values.conf it's possible to render the manifest by running the `kup-render.sh` script.

The script, as for its usage, has 2 options:

- `-f`: path to the file with the kup-values file.

- `-m`: optional, is the path to the directory with Kup's manifests.

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

It will create all the objects needed for Kup in the `kup-backup` project/namespace.
