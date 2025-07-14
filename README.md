# QuickStart Install Docker

## 在线安装 Docker

```bash
# 安装最新版本
export DOCKER_VERSION=v28.2.2 && \
mkdir -p /opt/docker && \
curl -sL https://cache.ali.wodcloud.com/kubernetes/ansible/ansible-docker.sh > /opt/docker/ansible-docker.sh && \
bash /opt/docker/ansible-docker.sh

# 安装历史版本
export DOCKER_VERSION=26.1.5 && \
mkdir -p /opt/docker && \
curl -sL https://cache.ali.wodcloud.com/kubernetes/ansible/ansible-docker.sh > /opt/docker/ansible-docker.sh && \
bash /opt/docker/ansible-docker.sh
```

## 离线安装 Docker

```bash
## amd64
mkdir -p /opt/docker/v28.2.2 && \
curl https://cache.ali.wodcloud.com/kubernetes/ansible/ansible-docker-v28.2.2-amd64.tgz > /opt/docker/ansible-docker-v28.2.2-amd64.tgz && \
tar -xzvf /opt/docker/ansible-docker-v28.2.2-amd64.tgz -C /opt/docker/v28.2.2 && \
bash /opt/docker/v28.2.2/scripts/install.sh

## arm64
mkdir -p /opt/docker/v28.2.2 && \
curl https://cache.ali.wodcloud.com/kubernetes/ansible/ansible-docker-v28.2.2-arm64.tgz > /opt/docker/ansible-docker-v28.2.2-arm64.tgz && \
tar -xzvf /opt/docker/ansible-docker-v28.2.2-arm64.tgz -C /opt/docker/v28.2.2 && \
bash /opt/docker/v28.2.2/scripts/install.sh
```

## 卸载 Docker

```bash
curl -sfL https://cache.ali.wodcloud.com/kubernetes/ansible/ansible-docker-uninstall.sh | sh -
```
