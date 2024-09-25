#!/bin/sh

export PATH=/usr/sbin:$PATH

set -ex

# 平台架构
TARGET_ARCH="${TARGET_ARCH:-amd64}"
# DOCKER版本
DOCKER_VERSION="${DOCKER_VERSION:-27.3.1}"

LOCAL_ARCH=$(uname -m)
if [ "$LOCAL_ARCH" = "x86_64" ]; then
  TARGET_ARCH="amd64"
elif [ "$(echo $LOCAL_ARCH | head -c 5)" = "armv8" ]; then
  TARGET_ARCH="arm64"
elif [ "$LOCAL_ARCH" = "aarch64" ]; then
  TARGET_ARCH="arm64"
elif [ "$LOCAL_ARCH" = "loongarch64" ]; then
  TARGET_ARCH="loong64"
else
  TARGET_ARCH="unsupported"
fi
if [ "$LOCAL_ARCH" = "unsupported" ]; then
  echo "This system's architecture ${LOCAL_ARCH} isn't supported"
  exit 0
fi

mkdir -p /opt/bin /opt/docker

if ! [ $(getent group docker) ]; then
  groupadd docker
fi

if ! (grep -q /opt/bin /etc/environment); then
  cat >/etc/environment <<-EOF
PATH="/opt/bin:$PATH"
EOF
fi

rm -rf /opt/bin/runc
cp /opt/docker/$DOCKER_VERSION/runc /opt/bin/runc

rm -rf /opt/bin/containerd \
  /opt/bin/containerd-shim \
  /opt/bin/containerd-shim-runc-v1 \
  /opt/bin/containerd-shim-runc-v2 \
  /opt/bin/containerd-stress \
  /opt/bin/ctr
cp /opt/docker/$DOCKER_VERSION/containerd /opt/bin/containerd
cp /opt/docker/$DOCKER_VERSION/containerd-shim-runc-v2 /opt/bin/containerd-shim-runc-v2
cp /opt/docker/$DOCKER_VERSION/containerd-stress /opt/bin/containerd-stress
cp /opt/docker/$DOCKER_VERSION/ctr /opt/bin/ctr

rm -rf /opt/bin/nerdctl
cp /opt/docker/$DOCKER_VERSION/nerdctl /opt/bin/nerdctl

rm -rf /opt/bin/docker \
  /opt/bin/dockerd \
  /opt/bin/docker-init \
  /opt/bin/docker-proxy
cp /opt/docker/$DOCKER_VERSION/docker /opt/bin/docker
cp /opt/docker/$DOCKER_VERSION/dockerd /opt/bin/dockerd
cp /opt/docker/$DOCKER_VERSION/docker-init /opt/bin/docker-init
cp /opt/docker/$DOCKER_VERSION/docker-proxy /opt/bin/docker-proxy

rm -rf /usr/libexec/docker/cli-plugins/docker-buildx
mkdir -p /usr/libexec/docker/cli-plugins
cp /opt/docker/$DOCKER_VERSION/docker-buildx /usr/libexec/docker/cli-plugins/docker-buildx

rm -rf /opt/cni/bin
mkdir -p /opt/cni/bin
cp /opt/docker/$DOCKER_VERSION/cni-plugins/* /opt/cni/bin

rm -rf /usr/local/bin/runc
ln -s /opt/docker/$DOCKER_VERSION/runc /usr/local/bin/runc

rm -rf /usr/local/bin/containerd \
  /usr/local/bin/containerd-shim \
  /usr/local/bin/containerd-shim-runc-v1 \
  /usr/local/bin/containerd-shim-runc-v2 \
  /usr/local/bin/containerd-stress \
  /usr/local/bin/ctr
ln -s /opt/docker/$DOCKER_VERSION/containerd /usr/local/bin/containerd
ln -s /opt/docker/$DOCKER_VERSION/containerd-shim-runc-v2 /usr/local/bin/containerd-shim-runc-v2
ln -s /opt/docker/$DOCKER_VERSION/containerd-stress /usr/local/bin/containerd-stress

rm -rf /usr/local/bin/nerdctl

rm -rf /usr/local/bin/docker \
  /usr/local/bin/dockerd \
  /usr/local/bin/docker-init \
  /usr/local/bin/docker-proxy
ln -s /opt/docker/$DOCKER_VERSION/dockerd /usr/local/bin/dockerd
ln -s /opt/docker/$DOCKER_VERSION/docker-init /usr/local/bin/docker-init
ln -s /opt/docker/$DOCKER_VERSION/docker-proxy /usr/local/bin/docker-proxy

if ! [ -e /opt/cni/bin/portmap ]; then
  mkdir -p /opt/cni/bin
  cp -r /opt/docker/$DOCKER_VERSION/cni-plugins/* /opt/cni/bin/
fi

if ! [ -x "$(command -v iptables)" ]; then
  cp -r /opt/docker/$DOCKER_VERSION/iptables/usr/* /usr/local/
fi

cp /opt/docker/$DOCKER_VERSION/service/containerd.service /etc/systemd/system/containerd.service
cp /opt/docker/$DOCKER_VERSION/service/docker.service /etc/systemd/system/docker.service

# docker , 重启docker时保持容器继续运行
if ! [ -e /etc/docker/daemon.json ]; then
  mkdir -p /etc/docker/
  cp /opt/docker/$DOCKER_VERSION/etc/docker/daemon.json /etc/docker/daemon.json
fi

# loong64 , loong64架构的基础镜像不支持seccomp，所以要关闭此设置
# if [ "$TARGET_ARCH" = "loong64" ]; then
#   if [ -e /etc/docker/daemon.json.bak ]; then
#     mv /etc/docker/daemon.json.bak /etc/docker/daemon.json.bak.`date +"%Y%m%d%H%M%S"`
#   fi
#   mv /etc/docker/daemon.json /etc/docker/daemon.json.bak
#   cat /etc/docker/daemon.json.bak | jq '."seccomp-profile"="unconfined"' > /etc/docker/daemon.json
# fi

systemctl daemon-reload
if ! [ -e /etc/systemd/system/multi-user.target.wants/containerd.service ]; then
  systemctl enable containerd.service
fi
systemctl restart containerd.service
if ! [ -e /etc/systemd/system/multi-user.target.wants/docker.socket ]; then
  systemctl enable docker.socket
fi
if ! [ -e /etc/systemd/system/multi-user.target.wants/docker.service ]; then
  systemctl enable docker.service
fi
systemctl restart docker.socket
systemctl restart docker.service
