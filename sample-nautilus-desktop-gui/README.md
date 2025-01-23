# Nautilus GUI Setup

## TLDR

Create a copy of this folder, then inside each file, change every instance of "cruzid" with your cruzid, and then run the command below to start your instance.

```bash
sh setup.sh 0
```

to start your desktop. Finally, go to the url mentioned in the desktop-ingres file, which would look like this `cruzid.nrp-nautilus.io`.

When you go to the url, it will ask for username and password. 

The username is `ubuntu`, and password is `aiea123`.

<br>

Once you are done using the GUI, run the following command to kill your deployment, if you don't the nautilus admins will find you, and they will ban you. (Jk, but not really...)

```bash
sh setup.sh 1
```

<br>

If you run into any issues, run:

```bash
sh setup.sh 2
sh setup.sh 0
```

## Setting Up CARLA

You can instal all the dependencies by running `carla_setup.sh` on the pod.

## Basics/Resources

WARNING: Before beginning this guide, please have a basic understanding of nautilus and have it setup on your computer. A quick start can be found here: https://docs.nationalresearchplatform.org/userdocs/start/quickstart/. To get namespace access, please email jowemorr@ucsc.edu or lgilpin@ucsc.edu.

This small guide is derived from these resources:
- CARLA on Nautilus: https://github.com/oliverc1623/ceriad/blob/main/nautilus-files/README.md
- Nautlius GUI Desktop: https://docs.nationalresearchplatform.org/userdocs/running/gui-desktop/
- Nautilus Storage: https://docs.nationalresearchplatform.org/userdocs/storage/intro/

A Nautilus desktop is a very similar process to creating a pod as it is a pod. This guide will guide through the process of creating and editing the specific yml files needed as well as launching the GUI.

## Creating the yml files

For our basic set up procedure there will be three files in total: storage, cache, and the desktop file.

### Storage

The format for storage files are thus:
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: examplevol
spec:
  storageClassName: <required storage class>
  accessModes:
  - <access mode, f.e. ReadWriteOnce >
  resources:
    requests:
      storage: <volume size, f.e. 20Gi>
```
There are four aspects that need to be changed to the desired value.
- name: An identifying name for the storage. For ease to differentiate cache and storage, add a "-cache" to the end of the name. (A suggestion is to use to some identifying naming scheme such as yourname/initial-purpose, such as k-carla)
- storageClassName: You may put any storage class name you desire. The names can be found in the storage folder on nautilus. (Such as rook-cephfs, seaweedfs-storage-nvme)
- accessModes: This determines the type of access others can have to the storage while it is running. 
- storage: The desired amount of storage.

To set up the two storage files we will use values for the aformentioned aspects:

```
For regular storage:

name: yourname/initial-purpose
storageClassName: seaweedfs-storage-nvme
accessModes: ReadWriteMany
storage: 256 Gi

For cache:

name: yourname/initial-purpose-cache
storageClassName: seaweedfs-storage-nvme
accessModes: ReadWriteMany
storage: 16 Gi
```

### Desktop

The framework file is supplied on the Nautilus GUI Desktop link, either the glx or egl desktop format can be used by egl is recommended. These both can be found under the usage subsection in the link.

As before, there are some aspecits requiring change. The changes are thus ('section'. identify the section these changes fall under on the file):
```
metadata/name: yourname/initial-desktop
name: TURN-PROTOCOL. value: "tcp"
limits.memory: 32Gi
requests.memory: 8Gi
requests.cpu: "4"
mountPath: Add /persistent to home/user to make home/user/persistent
```
CPU refers to the amount of cores requested.

Also, in the image section, replace ":latest" with ":22.04-20240425164112" to avoid compatibility issues.

For storage locate the volume subsection and change the code block as specified (with the chosen storage names):
```
name: dshm
emptyDir:
    medium: Memory
name: egl-cache-vol
persistentVolumeClaim:
    claimName: yourname/initial-purpose-cache
name: egl-root-vol
persistentVolumeClaim:
    claimName: yourname/initial-purpose
```
Make sure to remove the two "emptyDir: {}" lines. Accessing other existing volume containers is also possible via adding more lines of claims.

This finishes creating the appropriate files. These can be any name, but it is suggested to have the same system as yourname/initial at start for identification.

## Setting the networking

Before we can launch the desktop, we need to prepare another additional file. Our current files allow us to create the pods and storage volumes, which we can access via a method of port forwarding. However, this method is unstable and lacks performance. The appropriate method is to create an ingress and service file.

The file format is thus:
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: haproxy
  name: egl
spec:
  rules:
  - host: YOUR_ENDPOINT.nrp-nautilus.io
    http:
      paths:
      - backend:
          service:
            name: egl
            port:
              name: http
        path: /
        pathType: ImplementationSpecific
  tls:
  - hosts:
    - YOUR_ENDPOINT.nrp-nautilus.io
---
apiVersion: v1
kind: Service
metadata:
  name: egl
  labels:
    app: egl
spec:
  selector:
    app: egl
  ports:
  - name: http
    protocol: TCP
    port: 8080
```

Whilst this is one file, it has two parts: the ingress and the service. The ingress is part of the file above the "---". The changes here should be the following:
```
For both files, metadata.name = yourname/initial-desktop
Within ingress, replace backend.service.name with the above used name.
```
These steps finalize the labeling to differentiate the nautilus creations. 

We further need to set ours hosts, thus replace ```YOUR_ENDPOINT``` with any preferred hostname within the ingress section. Lastly, decide on a label to connect your service and deployment. This aswell can be any preferred name but the areas to place it in are:
```
In Service, spec.selector.app
In Desktop, spec.selector.matchLabels.app and spec.template.metadata.labels.app
```

## Accessing the Desktop

Now that all the files and their respective editing is done, the instances for those files have to be created.
Run the following commands in this order, replacing ```'name-descriptor'``` with the file name.

```
kubectl create -f 'name-storage'.yml
kubectl create -f 'name-cache'.yml
kubectl create -f 'name-desktop'.yml
kubectl create -f 'name-ingress'.yml
```
This will initialize all the required instances. After ensuring the pod is running, you can access the desktop via inputting```YOUR_ENDPOINT.nrp-nautilus.io``` into your browser (for any errors with hosting, please the check the Nautilus GUI guide), replacing ```YOUR_ENDPOINT``` appropriately. This process may take a few minutes. Furthermore, for the first login it may deliver a prompt asking for user and password, whose the values are ```user``` and ```mypass``` respectively.

After finishing work on the instances, delete them via:
```
kubectl delete ingress yourname/initial-desktop
kubectl delete deployment yourname/initial-desktop
```
You may delete storage using an identical process, however if work is saved on them it is not recommended.

To preserve any files on your Nautilus GUI Desktop, make sure to save them in the persistent folder in the home directory or else they will be cleared.To preserve any files on Nautilus GUI, make sure to save them in the persistent folder in the home directory or else they will be cleared on pod deletion.

To add carla to the desktop, use the added guide at the top of the page.
