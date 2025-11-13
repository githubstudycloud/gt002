#!/bin/bash
# Ubuntu 一键安装配置 net-tools 和 SSH 服务
# 使用方法: sudo bash setup-network-ssh.sh

echo "开始安装和配置 net-tools 和 SSH 服务..."

# 更新软件包列表
apt-get update -qq

# 安装 net-tools 和 openssh-server
apt-get install -y net-tools openssh-server

# 启动 SSH 服务
systemctl start ssh

# 设置 SSH 开机自启动
systemctl enable ssh

# 检查 SSH 服务状态
if systemctl is-active --quiet ssh; then
    echo "✓ SSH 服务已启动"
else
    echo "✗ SSH 服务启动失败"
    exit 1
fi

if systemctl is-enabled --quiet ssh; then
    echo "✓ SSH 服务已设置为开机自启动"
else
    echo "✗ SSH 开机自启动设置失败"
    exit 1
fi

echo ""
echo "=== 配置完成 ==="
echo "✓ net-tools 已安装（ifconfig, netstat 等命令可用）"
echo "✓ SSH 服务已安装并启动"
echo "✓ SSH 服务已设置为开机自启动"
echo ""
echo "SSH 服务状态:"
systemctl status ssh --no-pager -l
echo ""
echo "当前网络信息:"
ifconfig | grep -A 1 "inet "
