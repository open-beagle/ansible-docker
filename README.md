# QuickStart Install Docker

## 在线安装 Docker

```bash
# 安装最新版本
export DOCKER_VERSION=27.3.1 && \
mkdir -p /opt/docker && \
curl -sL https://cache.wodcloud.com/kubernetes/k8s/ansible/ansible-docker.sh > /opt/docker/ansible-docker.sh && \
bash /opt/docker/ansible-docker.sh

# 安装历史版本
export DOCKER_VERSION=26.1.5 && \
mkdir -p /opt/docker && \
curl -sL https://cache.wodcloud.com/kubernetes/k8s/ansible/ansible-docker.sh > /opt/docker/ansible-docker.sh && \
bash /opt/docker/ansible-docker.sh
```

## 离线安装 Docker

```bash
mkdir -p /opt/docker/27.3.1 && \
curl https://cache.wodcloud.com/kubernetes/k8s/ansible/ansible-docker-27.3.1-amd64.tgz > /opt/docker/ansible-docker-27.3.1-amd64.tgz && \
tar -xzvf /opt/docker/ansible-docker-27.3.1-amd64.tgz -C /opt/docker/27.3.1 && \
bash /opt/docker/27.3.1/scripts/install.sh
```

## 卸载 Docker

```bash
curl -sfL https://cache.wodcloud.com/kubernetes/k8s/ansible/ansible-docker-uninstall.sh | sh -
```
