# QuickStart Install Docker

```bash
# HTTPS服务器
HTTP_SERVER="https://cache.wodcloud.com/kubernetes"
# 平台架构
TARGET_ARCH="amd64"
# DOCKER版本
DOCKER_VERSION="23.0.4"

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
