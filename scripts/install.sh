#!/bin/sh

export PATH=/usr/sbin:$PATH

set -ex

# DOCKER版本
DOCKER_VERSION="${DOCKER_VERSION:-28.3.2}"

mkdir -p /opt/bin /opt/docker /opt/cni/bin

if ! [ $(getent group docker) ]; then
  groupadd docker
fi

# 安装bin/docker
if [ -L "/opt/docker/current" ] && [ "$(readlink -f "/opt/docker/current")" = "/opt/docker/${DOCKER_VERSION}" ]; then
  echo "版本${DOCKER_VERSION}，系统已安装，如若需要更新请先卸载。"
  exit 0
else
  rm -rf /opt/docker/current
  ln -s /opt/docker/${DOCKER_VERSION} /opt/docker/current
fi
rm -rf /usr/libexec/docker/cli-plugins/docker-buildx
mkdir -p /usr/libexec/docker/cli-plugins
ln -s /opt/docker/${DOCKER_VERSION}/bin/docker-buildx /usr/libexec/docker/cli-plugins/docker-buildx

# 将 buildctl, ctr, docker, nerdctl 命令安装至全局
rm -rf /opt/bin/buildctl
rm -rf /opt/bin/ctr
rm -rf /opt/bin/docker
rm -rf /opt/bin/dasel
rm -rf /opt/bin/nerdctl
rm -rf /opt/bin/yq
ln -s /opt/docker/${DOCKER_VERSION}/bin/buildctl /opt/bin/buildctl
ln -s /opt/docker/${DOCKER_VERSION}/bin/ctr /opt/bin/ctr
ln -s /opt/docker/${DOCKER_VERSION}/bin/docker /opt/bin/docker
ln -s /opt/docker/${DOCKER_VERSION}/bin/dasel /opt/bin/dasel
ln -s /opt/docker/${DOCKER_VERSION}/bin/nerdctl /opt/bin/nerdctl
ln -s /opt/docker/${DOCKER_VERSION}/bin/yq /opt/bin/yq

rm -rf /usr/local/bin/buildctl
rm -rf /usr/local/bin/ctr
rm -rf /usr/local/bin/docker
rm -rf /usr/local/bin/dasel
rm -rf /usr/local/bin/nerdctl
rm -rf /usr/local/bin/yq
ln -s /opt/docker/${DOCKER_VERSION}/bin/buildctl /usr/local/bin/buildctl
ln -s /opt/docker/${DOCKER_VERSION}/bin/ctr /usr/local/bin/ctr
ln -s /opt/docker/${DOCKER_VERSION}/bin/docker /usr/local/bin/docker
ln -s /opt/docker/${DOCKER_VERSION}/bin/dasel /usr/local/bin/dasel
ln -s /opt/docker/${DOCKER_VERSION}/bin/nerdctl /usr/local/bin/nerdctl
ln -s /opt/docker/${DOCKER_VERSION}/bin/yq /usr/local/bin/yq

# 安装cni
mkdir -p /opt/cni/bin
for file in /opt/docker/${DOCKER_VERSION}/cni-plugins/*; do
  filename=$(basename "$file")
  if [ -e "/opt/cni/bin/$filename" ]; then
    rm -f "/opt/cni/bin/$filename"
  fi
  ln -s "$file" "/opt/cni/bin/$filename"
done

# 安装iptables
if ! [ -x "$(command -v iptables)" ]; then
  cp -r /opt/docker/${DOCKER_VERSION}/iptables/usr/* /usr/local/
fi

cp /opt/docker/${DOCKER_VERSION}/service/containerd.service /etc/systemd/system/containerd.service
cp /opt/docker/${DOCKER_VERSION}/service/docker.socket /etc/systemd/system/docker.socket
cp /opt/docker/${DOCKER_VERSION}/service/docker.service /etc/systemd/system/docker.service
systemctl daemon-reload

# docker , 重启docker时保持容器继续运行
if ! [ -e /etc/docker/daemon.json ]; then
  mkdir -p /etc/docker/
  cp /opt/docker/${DOCKER_VERSION}/etc/docker/daemon.json /etc/docker/daemon.json
fi

if ! [ -e /etc/systemd/system/multi-user.target.wants/containerd.service ]; then
  systemctl enable containerd.service
fi
systemctl restart containerd.service
if ! [ -e /etc/systemd/system/sockets.target.wants/docker.socket ]; then
  systemctl enable docker.socket
  systemctl restart docker.socket
fi
if ! [ -e /etc/systemd/system/multi-user.target.wants/docker.service ]; then
  systemctl enable docker.service
fi
systemctl restart docker.service

cp /opt/docker/${DOCKER_VERSION}/service/buildkit.socket /etc/systemd/system/buildkit.socket
cp /opt/docker/${DOCKER_VERSION}/service/buildkit.service /etc/systemd/system/buildkit.service
systemctl daemon-reload

if ! [ -e /etc/systemd/system/sockets.target.wants/buildkit.socket ]; then
  systemctl enable buildkit.socket
  systemctl restart buildkit.socket
fi
if ! [ -e /etc/systemd/system/multi-user.target.wants/buildkit.service ]; then
  systemctl enable buildkit.service
fi
systemctl restart buildkit.service
