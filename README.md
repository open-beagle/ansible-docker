# QuickStart Install Docker

## 在线安装 Docker

```bash
sudo curl -sfL https://cache.wodcloud.com/kubernetes/k8s/docker/install.sh | sh -

# 安装历史版本
export DOCKER_VERSION=26.1.5
sudo curl -sfL https://cache.wodcloud.com/kubernetes/k8s/docker/install.sh | sh -
```

## 离线安装 Docker

```bash
# HTTPS服务器
HTTP_SERVER="https://cache.wodcloud.com"
# 平台架构 amd64 arm64 loong64
TARGET_ARCH="amd64"
# DOCKER版本
DOCKER_VERSION="27.2.1"

mkdir -p /opt/docker
# 下载文件
# docker-$DOCKER_VERSION.tgz 68MB
curl $HTTP_SERVER/kubernetes/k8s/docker/$TARGET_ARCH/docker-$DOCKER_VERSION.tgz > /opt/docker/docker-$DOCKER_VERSION.tgz
# 解压文件
mkdir -p /opt/docker/$DOCKER_VERSION
tar -xzvf /opt/docker/docker-${DOCKER_VERSION}.tgz -C /opt/docker/$DOCKER_VERSION

# 安装Docker
bash /opt/docker/${DOCKER_VERSION}/install.sh
```

## 卸载 Docker

```bash
sudo curl -sfL https://cache.wodcloud.com/kubernetes/k8s/docker/uninstall.sh | sh -
```

## 版本说明

- v26 , 早期版本，将会使用 runc v1 ， contaienrd v1 ，适配持续集成等古早与 Docker 集成的软件 .
- main , v27++ ， 使用了 Containerd v2 ， 暂时与持续集成冲突 ， 请不要使用在生产环境 .
