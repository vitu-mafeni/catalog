# catalog customized
Nephio Package Catalog 


## Debugging Istio Issues
Istio CNI cannot write /etc/cni/net.d/10-flannel.conflist

because the node has hit ulimit (open file descriptor cap).
Once it fails, it deletes itself and leaves the node in a broken CNI state → ALL Kubeflow pods with sidecars fail.

============================================================
ROOT CAUSE (confirmed)

1. CNI tries to:
- copy binaries
- write kubeconfig
- write chained CNI config
2. Kernel returns:
- too many open files
3. Istio CNI agent tears down and exits
4. Cluster now has:
- flannel CNI not chained
- no valid Istio CNI
    → Pods stuck in Init:Error

============================================================
SOLUTION (FIX ULIMIT + RESTART CNI)

### A. Increase allowed file handles on all nodes

Run this on each worker node:
```bash
sudo bash -c 'echo "* soft nofile 65536" >> /etc/security/limits.conf'
sudo bash -c 'echo "* hard nofile 65536" >> /etc/security/limits.conf'
sudo bash -c 'echo "fs.inotify.max_user_watches=524288" >> /etc/sysctl.conf'
sudo bash -c 'echo "fs.inotify.max_user_instances=2048" >> /etc/sysctl.conf'
sudo sysctl -p
```

Then confirm:
```bash
ulimit -n
```

Should output 65536

If not:
Reboot the node:
```bash
sudo reboot
```

### B. Restart the Istio CNI DaemonSet

After nodes return:
```bash
kubectl rollout restart ds istio-cni-node -n kube-system
```

Verify:
```bash
kubectl get pods -n kube-system | grep istio-cni
```

Logs should no longer show errors.


## CREATE THE NFS SYSTEM

Use this command for default storage
```bash
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --set nfs.server=x.x.x.x \
    --set nfs.path=/exported/path
```
Then additional one with this:
```bash
helm install nfs-csi nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --set nfs.server=192.168.0.7 \
  --set nfs.path=/srv/nfs/k8s \
  --set storageClass.name=nfs-csi \
  --set storageClass.defaultClass=false
```

### Install on the host server
```bash 
sudo apt install nfs-kernel-server -y
sudo systemctl start nfs-kernel-server.service
```
### Configuration
```bash
sudo mkdir /srv/nfs/k8s -p
sudo chmod 777 /srv/nfs/k8s
chown -R nobody:nogroup /srv/nfs/k8s
```
You can configure the directories to be exported by adding them to the __/etc/exports file__. For example:
```text
/srv/nfs/k8s *(rw,async,no_subtree_check,no_root_squash)
```
```bash
sudo exportfs -a
```
### Install on all k8s workers
```bash
sudo apt install nfs-common -y

```