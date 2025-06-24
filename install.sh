#!/bin/sh

set -ex

# HTTPS服务器
HTTP_SERVER="${HTTP_SERVER:-https://cache.ali.wodcloud.com}"
# 平台架构
TARGET_ARCH="${TARGET_ARCH:-amd64}"
# DOCKER版本
DOCKER_VERSION="${DOCKER_VERSION:-28.2.2}"

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

if ! [ -e /opt/docker/${DOCKER_VERSION}/scripts/install.sh ]; then
  rm -rf /opt/docker/$DOCKER_VERSION
  mkdir -p /opt/docker/$DOCKER_VERSION
  # 下载文件
  # ansible-docker-${DOCKER_VERSION}-$TARGET_ARCH.tgz 68MB
  if ! [ -e /opt/docker/ansible-docker-${DOCKER_VERSION}-$TARGET_ARCH.tgz ]; then
    # 下载文件
    # ansible-docker-${DOCKER_VERSION}-$TARGET_ARCH.tgz 68MB
    curl -fL $HTTP_SERVER/kubernetes/ansible/ansible-docker-v${DOCKER_VERSION}-$TARGET_ARCH.tgz >/opt/docker/ansible-docker-${DOCKER_VERSION}-$TARGET_ARCH.tgz
  fi
  tar -xzvf /opt/docker/ansible-docker-${DOCKER_VERSION}-$TARGET_ARCH.tgz -C /opt/docker/$DOCKER_VERSION
  rm -rf /opt/docker/ansible-docker-${DOCKER_VERSION}-$TARGET_ARCH.tgz
fi

. /opt/docker/${DOCKER_VERSION}/scripts/install.sh
