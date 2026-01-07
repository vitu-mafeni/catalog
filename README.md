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