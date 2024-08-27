#!/bin/sh

export PATH=/usr/sbin:$PATH

set -ex

# HTTPS服务器
HTTP_SERVER="${HTTP_SERVER:-https://cache.wodcloud.com}"
# 平台架构
TARGET_ARCH="${TARGET_ARCH:-amd64}"
# DOCKER版本
DOCKER_VERSION="${DOCKER_VERSION:-26.1.5}"

LOCAL_ARCH=$(uname -m)
if [ "$LOCAL_ARCH" = "x86_64" ]; then
  TARGET_ARCH="amd64"
elif [ "$(echo $LOCAL_ARCH | head -c 5)" = "armv8" ]; then
  TARGET_ARCH="arm64"
elif [ "$LOCAL_ARCH" = "aarch64" ]; then
  TARGET_ARCH="arm64"
elif [ "$LOCAL_ARCH" = "loongarch64" ]; then
  TARGET_ARCH="loong64"
elif [ "$(echo $LOCAL_ARCH | head -c 5)" = "ppc64" ]; then
  TARGET_ARCH="ppc64le"
elif [ "$(echo $LOCAL_ARCH | head -c 6)" = "mips64" ]; then
  TARGET_ARCH="mips64le"
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

ENV_OPT="/opt/bin:$PATH"
if ! (grep -q /opt/bin /etc/environment); then
  cat >/etc/environment <<-EOF
PATH="${ENV_OPT}"
EOF
fi

if [ -e /opt/docker/docker-$DOCKER_VERSION.md ]; then
  exit 0
fi

if ! [ -e /opt/docker/docker-$DOCKER_VERSION.tgz ]; then
  mkdir -p /opt/docker
  # 下载文件
  # docker-$DOCKER_VERSION.tgz 68MB
  curl $HTTP_SERVER/kubernetes/k8s/docker/$TARGET_ARCH/docker-$DOCKER_VERSION.tgz >/opt/docker/docker-$DOCKER_VERSION.tgz
fi

mkdir -p /opt/docker/$DOCKER_VERSION
tar -xzvf /opt/docker/docker-$DOCKER_VERSION.tgz -C /opt/docker/$DOCKER_VERSION
rm -rf /opt/docker/docker-$DOCKER_VERSION.tgz
touch /opt/docker/docker-$DOCKER_VERSION.md

rm -rf /opt/bin/runc
cp /opt/docker/$DOCKER_VERSION/runc /opt/bin/runc

rm -rf /opt/bin/ctr /opt/bin/containerd /opt/bin/containerd-shim /opt/bin/containerd-shim-runc-v2
cp /opt/docker/$DOCKER_VERSION/ctr /opt/bin/ctr
cp /opt/docker/$DOCKER_VERSION/containerd /opt/bin/containerd
cp /opt/docker/$DOCKER_VERSION/containerd-shim /opt/bin/containerd-shim
cp /opt/docker/$DOCKER_VERSION/containerd-shim-runc-v2 /opt/bin/containerd-shim-runc-v2

rm -rf /opt/bin/nerdctl
cp /opt/docker/$DOCKER_VERSION/nerdctl /opt/bin/nerdctl

rm -rf /opt/bin/docker /opt/bin/dockerd /opt/bin/docker-init /opt/bin/docker-proxy
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

rm -rf /usr/local/bin/ctr /usr/local/bin/containerd /usr/local/bin/containerd-shim /usr/local/bin/containerd-shim-runc-v2
ln -s /opt/docker/$DOCKER_VERSION/ctr /usr/local/bin/ctr
ln -s /opt/docker/$DOCKER_VERSION/containerd /usr/local/bin/containerd
ln -s /opt/docker/$DOCKER_VERSION/containerd-shim /usr/local/bin/containerd-shim
ln -s /opt/docker/$DOCKER_VERSION/containerd-shim-runc-v2 /usr/local/bin/containerd-shim-runc-v2

rm -rf /usr/local/bin/nerdctl
cp /opt/docker/$DOCKER_VERSION/nerdctl /usr/local/bin/nerdctl

rm -rf /usr/local/bin/docker /usr/local/bin/dockerd /usr/local/bin/docker-init /usr/local/bin/docker-proxy
ln -s /opt/docker/$DOCKER_VERSION/docker /usr/local/bin/docker
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

cat >/etc/systemd/system/containerd.service <<\EOF
# Copyright The containerd Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target

[Service]
#如无法正确下载镜像开启以下参数
#某些开启了杀毒软件的主机可能会在没有MountFags=slave的情况下阻止大型超过300MB的镜像Layer卸载unmount
#https://github.com/containerd/containerd/issues/5538
MountFlags=slave

#uncomment to enable the experimental sbservice (sandboxed) version of containerd/cri integration
#Environment="ENABLE_CRI_SANDBOXES=sandboxed"
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/opt/bin/containerd

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
LimitNOFILE=infinity
# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target

EOF

cat >/etc/systemd/system/docker.socket <<\EOF
[Unit]
Description=Docker Socket for the API

[Socket]
ListenStream=/var/run/docker.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target

EOF

cat >/etc/systemd/system/docker.service <<\EOF
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service containerd.service
Wants=network-online.target containerd.service
Requires=docker.socket 

[Service]
Type=notify
# the default is not to use systemd for cgroups because the delegate issues still
# exists and systemd currently does not support the cgroup feature set required
# for containers run by docker
Environment=PATH=/opt/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin
ExecStart=/opt/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
ExecReload=/bin/kill -s HUP $MAINPID
TimeoutSec=0
RestartSec=2
Restart=always

# Note that StartLimit* options were moved from "Service" to "Unit" in systemd 229.
# Both the old, and new location are accepted by systemd 229 and up, so using the old location
# to make them work for either version of systemd.
StartLimitBurst=3

# Note that StartLimitInterval was renamed to StartLimitIntervalSec in systemd 230.
# Both the old, and new name are accepted by systemd 230 and up, so using the old name to make
# this option work for either version of systemd.
StartLimitInterval=60s

# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity

# Comment TasksMax if your systemd version does not support it.
# Only systemd 226 and above support this option.
TasksMax=infinity

# set delegate yes so that systemd does not reset the cgroups of docker containers
Delegate=yes

# kill only the docker process, not all processes in the cgroup
KillMode=process
OOMScoreAdjust=-500

[Install]
WantedBy=multi-user.target

EOF

# docker , 重启docker时保持容器继续运行
mkdir -p /etc/docker/
if ! [ -e /etc/docker/daemon.json ]; then
  cat >>/etc/docker/daemon.json <<-EOF
{
  "live-restore": true,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  }
}
EOF
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
if ! [ -e /etc/systemd/system/multi-user.target.wants/docker.service ]; then
  systemctl enable docker.socket
  systemctl enable docker.service
fi
systemctl restart docker.socket
systemctl restart docker.service
