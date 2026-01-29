# cluster

## Description

This package provides a blueprint for deploying a capi cluster using the aws  templates
- The default package provides installation to use containerd. If you require to use cri-o, please replace KubeadmConfigTemplate and KubeadmControlPlane resources with the following: 
### 1. KubeadmConfigTemplate
```yaml
apiVersion: bootstrap.cluster.x-k8s.io/v1beta1
kind: KubeadmConfigTemplate
metadata: # kpt-merge: default/aws-nephio-md-0
  name: aws-nephio-md-0
  namespace: default
  annotations:
    nephio.org/cluster-name: aws-nephio
spec:
  template:
    spec:
      preKubeadmCommands:
      - |
        # Disable containerd
        systemctl disable containerd --now || true
        
        # Install CRI-O 1.34
        mkdir -p /etc/apt/keyrings

        curl -fsSL https://download.opensuse.org/repositories/isv:/cri-o:/stable:/v1.34/deb/Release.key |
        gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg

        echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://download.opensuse.org/repositories/isv:/cri-o:/stable:/v1.34/deb/ /" |
        tee /etc/apt/sources.list.d/cri-o.list

        apt-get update
        apt-get install -y cri-o
        systemctl enable crio --now

        # Configure kubelet
        mkdir -p /etc/systemd/system/kubelet.service.d
        cat <<EOF >/etc/systemd/system/kubelet.service.d/10-crio.conf
        [Service]
        Environment="KUBELET_EXTRA_ARGS=--container-runtime-endpoint=unix:///var/run/crio/crio.sock"
        EOF

        systemctl daemon-reload
        systemctl restart kubelet
      joinConfiguration:
        nodeRegistration:
          name: '{{ ds.meta_data.local_hostname }}'
          criSocket: unix:///var/run/crio/crio.sock
          kubeletExtraArgs:
            cloud-provider: external
            node-ip: '{{ ds.meta_data.local_ipv4 }}'
``` 
### 2. KubeadmControlPlane
```yaml
apiVersion: controlplane.cluster.x-k8s.io/v1beta1
kind: KubeadmControlPlane
metadata: # kpt-merge: default/aws-nephio-control-plane
  name: aws-nephio-control-plane
  namespace: default
  annotations:
    nephio.org/cluster-name: aws-nephio
spec:
  version: v1.32.0
  replicas: 1
  kubeadmConfigSpec:
    preKubeadmCommands:
    - |
      # Disable containerd
      systemctl disable containerd --now || true

      # Install CRI-O 1.34
      mkdir -p /etc/apt/keyrings

      curl -fsSL https://download.opensuse.org/repositories/isv:/cri-o:/stable:/v1.34/deb/Release.key |
      gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg

      echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://download.opensuse.org/repositories/isv:/cri-o:/stable:/v1.34/deb/ /" |
      tee /etc/apt/sources.list.d/cri-o.list

      apt-get update
      apt-get install -y cri-o
      systemctl enable crio --now

      # Configure kubelet to use CRI-O (K8s 1.32 compatible)
      mkdir -p /etc/systemd/system/kubelet.service.d
      cat <<EOF >/etc/systemd/system/kubelet.service.d/10-crio.conf
      [Service]
      Environment="KUBELET_EXTRA_ARGS=--container-runtime-endpoint=unix:///var/run/crio/crio.sock"
      EOF

      systemctl daemon-reload
      systemctl restart kubelet
    clusterConfiguration:
      apiServer:
        extraArgs:
          cloud-provider: external
      controllerManager:
        extraArgs:
          cloud-provider: external
    initConfiguration:
      nodeRegistration:
        name: '{{ ds.meta_data.local_hostname }}'
        criSocket: unix:///var/run/crio/crio.sock
        kubeletExtraArgs:
          cloud-provider: external
    joinConfiguration:
      nodeRegistration:
        name: '{{ ds.meta_data.local_hostname }}'
        criSocket: unix:///var/run/crio/crio.sock
        kubeletExtraArgs:
          cloud-provider: external
  machineTemplate:
    infrastructureRef:
      apiVersion: infrastructure.cluster.x-k8s.io/v1beta2
      kind: AWSMachineTemplate
      name: aws-nephio-control-plane
```
