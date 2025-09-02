apiVersion: bootstrap.cluster.x-k8s.io/v1beta1
kind: KubeadmConfigTemplate
metadata:
  name: my-cluster-md-0
spec:
  template:
    spec:
      postKubeadmCommands:
        - |
          # Ensure correct apt sources
          cat <<EOF >/etc/apt/sources.list
          deb http://archive.ubuntu.com/ubuntu jammy main restricted universe multiverse
          deb http://archive.ubuntu.com/ubuntu jammy-updates main restricted universe multiverse
          deb http://archive.ubuntu.com/ubuntu jammy-security main restricted universe multiverse
          EOF

        - apt-get update
        - DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

        # Fix broken packages if any
        - apt-get --fix-broken install -y || true
        - dpkg --configure -a || true

        # Unhold in case criu dependencies are pinned
        - apt-mark unhold libcap2 libgnutls30 libtasn1-6 || true

        # Install CRIU build dependencies
        - DEBIAN_FRONTEND=noninteractive apt-get install -y \
            gcc xmlto build-essential asciidoc \
            libprotobuf-dev libprotobuf-c-dev protobuf-c-compiler protobuf-compiler python3-protobuf \
            pkg-config uuid-dev libbsd-dev libnftables-dev libcap-dev \
            libnl-3-dev libnet1-dev libaio-dev libgnutls28-dev libdrm-dev --no-install-recommends

        # Build CRIU from source
        - cd /tmp
        - wget https://github.com/checkpoint-restore/criu/archive/v4.1.1/criu-4.1.1.tar.gz
        - tar -xvf criu-4.1.1.tar.gz
        - cd criu-4.1.1
        - make
        - make install
        - criu -V