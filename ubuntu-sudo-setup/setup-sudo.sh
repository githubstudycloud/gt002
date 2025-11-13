#!/bin/bash
# Ubuntu 用户免 sudo 配置脚本
# 使用方法: sudo bash setup-sudo.sh <username>

USERNAME="${1:-$USER}"

echo "正在配置用户 $USERNAME 免 sudo..."

# 将用户加入 sudo 组并配置免密码 sudo
usermod -aG sudo "$USERNAME" && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/"$USERNAME" > /dev/null && chmod 0440 /etc/sudoers.d/"$USERNAME" && echo "✓ 配置完成！用户 $USERNAME 已加入 sudo 组并配置免密码 sudo。请重新登录生效。"
