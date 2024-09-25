# QuickStart Install Docker

## 在线安装 Docker

```bash
# 安装最新版本
export DOCKER_VERSION=27.3.1 && \
curl -sL https://cache.wodcloud.com/kubernetes/k8s/docker/install.sh > /opt/docker/install.sh && \
bash /opt/docker/install.sh

# 安装历史版本
export DOCKER_VERSION=26.1.5 && \
curl -sL https://cache.wodcloud.com/kubernetes/k8s/docker/install.sh > /opt/docker/install.sh && \
bash /opt/docker/install.sh
```

## 离线安装 Docker

```bash
mkdir -p /opt/docker/27.3.1 && \
curl https://cache.wodcloud.com/kubernetes/k8s/docker/amd64/docker-27.3.1.tgz > /opt/docker/docker-27.3.1.tgz && \
tar -xzvf /opt/docker/docker-27.3.1.tgz -C /opt/docker/27.3.1 && \
bash /opt/docker/27.3.1/scripts/install.sh
```

## 卸载 Docker

```bash
curl -sfL https://cache.wodcloud.com/kubernetes/k8s/docker/uninstall.sh | sh -
```

## 版本说明

- v26 , 早期版本，将会使用 runc v1 ， contaienrd v1 ，适配持续集成等古早与 Docker 集成的软件 .
- main , v27++ ， 使用了 Containerd v2 ， 暂时与持续集成冲突 ， 请不要使用在生产环境 .
