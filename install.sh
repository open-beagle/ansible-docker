#!/bin/bash

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

if ! [ -e /opt/docker/${DOCKER_VERSION}/docker ]; then
  mkdir -p /opt/docker
  # 下载文件
  # docker-${DOCKER_VERSION}.tgz 68MB
  curl $HTTP_SERVER/kubernetes/k8s/docker/$TARGET_ARCH/docker-${DOCKER_VERSION}.tgz >/opt/docker/docker-${DOCKER_VERSION}.tgz
  mkdir -p /opt/docker/$DOCKER_VERSION
  tar -xzvf /opt/docker/docker-${DOCKER_VERSION}.tgz -C /opt/docker/$DOCKER_VERSION
  rm -rf /opt/docker/docker-${DOCKER_VERSION}.tgz
fi

source /opt/docker/${DOCKER_VERSION}/install.sh
