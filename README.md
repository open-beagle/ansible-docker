# QuickStart Install Docker

## 在线安装 Docker

```bash
sudo curl -sfL https://cache.wodcloud.com/kubernetes/k8s/docker/install.sh | sh -
```

## 离线安装 Docker

```bash
# HTTPS服务器
HTTP_SERVER="https://cache.wodcloud.com"
# 平台架构 amd64 arm64 ppc64le mips64le loong64
TARGET_ARCH="amd64"
# DOCKER版本
DOCKER_VERSION="23.0.6"

mkdir -p /opt/docker
# 下载文件
# docker-$DOCKER_VERSION.tgz 68MB
curl $HTTP_SERVER/kubernetes/k8s/docker/$TARGET_ARCH/docker-$DOCKER_VERSION.tgz > /opt/docker/docker-$DOCKER_VERSION.tgz
# 下载文件
# install.sh
curl $HTTP_SERVER/kubernetes/k8s/docker/install.sh > /opt/docker/install.sh

# 安装Docker
bash /opt/docker/install.sh
```

## 卸载 Docker

```bash
sudo curl -sfL https://cache.wodcloud.com/kubernetes/k8s/docker/uninstall.sh | sh -
```