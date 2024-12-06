#!/bin/sh

export PATH=/usr/sbin:$PATH

set -ex

# 平台架构
TARGET_ARCH="${TARGET_ARCH:-amd64}"
# DOCKER版本
DOCKER_VERSION="${DOCKER_VERSION:-27.3.2}"

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

if [ -e /opt/bin/docker ]; then
  # 获取当前 Docker 版本
  current_version=$(/opt/bin/docker version --format '{{.Server.Version}}')
  # 比较版本
  if [ "$current_version" = "${DOCKER_VERSION}-beagle" ]; then
    echo "版本一致 $current_version , 无需安装."
    exit 0
  fi
fi

mkdir -p /opt/bin /opt/docker /opt/cni/bin

if ! [ $(getent group docker) ]; then
  groupadd docker
fi

if ! (grep -q /opt/bin /etc/environment); then
  cat >/etc/environment <<-EOF
PATH="/opt/bin:$PATH"
EOF
fi

# 安装bin/docker
for file in /opt/docker/$DOCKER_VERSION/bin/*; do
  filename=$(basename "$file")
  rm -f /opt/bin/$filename /usr/local/bin/$filename
  cp "$file" "/opt/bin/$filename"
done
rm -rf /opt/bin/docker-buildx /usr/libexec/docker/cli-plugins/docker-buildx
mkdir -p /usr/libexec/docker/cli-plugins
cp /opt/docker/$DOCKER_VERSION/bin/docker-buildx /usr/libexec/docker/cli-plugins/docker-buildx

# 将docker , nerdctl 命令安装至全局
ln -s /opt/docker/$DOCKER_VERSION/bin/docker /usr/local/bin/docker
ln -s /opt/docker/$DOCKER_VERSION/bin/nerdctl /usr/local/bin/nerdctl

# 安装cni
for file in /opt/docker/$DOCKER_VERSION/cni-plugins/*; do
  filename=$(basename "$file")
  rm -f /opt/cni/bin/$filename
  cp "$file" /opt/cni/bin/
done

if ! [ -x "$(command -v iptables)" ]; then
  cp -r /opt/docker/$DOCKER_VERSION/iptables/usr/* /usr/local/
fi

cp /opt/docker/$DOCKER_VERSION/service/containerd.service /etc/systemd/system/containerd.service
cp /opt/docker/$DOCKER_VERSION/service/docker.socket /etc/systemd/system/docker.socket
cp /opt/docker/$DOCKER_VERSION/service/docker.service /etc/systemd/system/docker.service

# docker , 重启docker时保持容器继续运行
if ! [ -e /etc/docker/daemon.json ]; then
  mkdir -p /etc/docker/
  cp /opt/docker/$DOCKER_VERSION/etc/docker/daemon.json /etc/docker/daemon.json
fi

systemctl daemon-reload
if ! [ -e /etc/systemd/system/multi-user.target.wants/containerd.service ]; then
  systemctl enable containerd.service
fi
systemctl restart containerd.service
if ! [ -e /etc/systemd/system/multi-user.target.wants/docker.socket ]; then
  systemctl enable docker.socket
  systemctl restart docker.socket
fi
if ! [ -e /etc/systemd/system/multi-user.target.wants/docker.service ]; then
  systemctl enable docker.service
fi
systemctl restart docker.service
