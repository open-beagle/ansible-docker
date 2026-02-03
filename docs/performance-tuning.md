# Docker/Containerd 性能优化指南

解决大型镜像 layer（10G+）解压缓慢的问题。

## 问题诊断

```bash
# 1. 检查存储驱动（应该是 overlay2）
docker info | grep "Storage Driver"

# 2. 检查磁盘类型（rota=0 表示 SSD）
lsblk -d -o name,rota

# 3. 检查文件系统类型（推荐 ext4 或 xfs）
df -Th /var/lib/docker

# 4. 检查 Native Overlay Diff（应该是 true）
docker info | grep -i "native overlay diff"

# 5. 检查内核 metacopy 支持
cat /sys/module/overlay/parameters/metacopy

# 6. 检查内核版本（4.19+ 支持 metacopy，5.x+ 更佳）
uname -r
```

## 优化步骤

### 1. 开启内核 overlay 优化参数

```bash
# 开启 metacopy（避免复制整个文件，只复制元数据）
echo "Y" | sudo tee /sys/module/overlay/parameters/metacopy

# 开启 redirect_dir（目录重定向优化）
echo "Y" | sudo tee /sys/module/overlay/parameters/redirect_dir

# 永久生效
cat << 'EOF' | sudo tee /etc/modprobe.d/overlay.conf
options overlay metacopy=on redirect_dir=on
EOF
```

### 2. 优化 Docker daemon.json

编辑 `/etc/docker/daemon.json`：

```json
{
  "live-restore": true,
  "storage-driver": "overlay2",
  "storage-opts": ["overlay2.override_kernel_check=true"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  }
}
```

### 3. 优化 containerd 配置

编辑 `/etc/containerd/config.toml`：

```toml
[plugins."io.containerd.grpc.v1.cri"]
max_concurrent_downloads = 10  # 默认是 3

[plugins."io.containerd.transfer.v1.local"]
max_concurrent_downloads = 10
max_concurrent_uploaded_layers = 10
```

### 4. 启用 MountFlags=slave

编辑 `/etc/systemd/system/containerd.service`，在 `[Service]` 段添加：

```ini
MountFlags=slave
```

这解决大型 layer（>300MB）mount/unmount 卡住的问题。

### 5. 重启服务

```bash
systemctl daemon-reload
systemctl restart containerd
systemctl restart docker
```

## 验证优化效果

```bash
# 1. 确认 metacopy 已开启
cat /sys/module/overlay/parameters/metacopy  # 应该显示 Y

# 2. 确认 redirect_dir 已开启
cat /sys/module/overlay/parameters/redirect_dir  # 应该显示 Y

# 3. 测试本地解压速度（排除网络因素）
time docker save nginx:latest | docker load

# 4. 测试磁盘写入速度（应该 > 200MB/s）
dd if=/dev/zero of=/data/testfile bs=1G count=5 oflag=direct status=progress
rm -f /data/testfile

# 5. 拉取大镜像测试
time docker pull <your-large-image>
```

## 进阶优化（可选）

如果以上优化后仍然较慢，可以考虑：

1. **懒加载方案** - stargz-snapshotter 或 nydus，不需要完整解压 layer 就能启动容器
2. **镜像加速** - 使用本地 registry mirror
3. **硬件检查** - 确认 SSD 健康状态，检查 RAID 配置是否合理

## 参考链接

- [containerd issue #5538](https://github.com/containerd/containerd/issues/5538) - MountFlags=slave 相关
- [Overlay Filesystem](https://www.kernel.org/doc/html/latest/filesystems/overlayfs.html) - 内核文档
