#!/bin/bash
# Ubuntu Desktop 性能模式配置脚本（安全版本 - 不强制重启会话）
# 使用方法: sudo bash setup-performance-mode-safe.sh

echo "开始配置 Ubuntu Desktop 性能模式（安全版本）..."

# 禁用系统休眠和睡眠
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# 配置 systemd-logind 不自动挂起
if [ -f /etc/systemd/logind.conf ]; then
    # 备份原配置文件
    cp /etc/systemd/logind.conf /etc/systemd/logind.conf.backup

    # 修改配置
    sed -i 's/^#*HandleLidSwitch=.*/HandleLidSwitch=ignore/' /etc/systemd/logind.conf
    sed -i 's/^#*HandleLidSwitchExternalPower=.*/HandleLidSwitchExternalPower=ignore/' /etc/systemd/logind.conf
    sed -i 's/^#*IdleAction=.*/IdleAction=ignore/' /etc/systemd/logind.conf

    # 如果配置项不存在，则添加
    grep -q "^HandleLidSwitch=" /etc/systemd/logind.conf || echo "HandleLidSwitch=ignore" >> /etc/systemd/logind.conf
    grep -q "^HandleLidSwitchExternalPower=" /etc/systemd/logind.conf || echo "HandleLidSwitchExternalPower=ignore" >> /etc/systemd/logind.conf
    grep -q "^IdleAction=" /etc/systemd/logind.conf || echo "IdleAction=ignore" >> /etc/systemd/logind.conf

    echo "✓ systemd-logind 配置已更新"
fi

echo ""
echo "=== 配置完成 ==="
echo "✓ 系统休眠、睡眠、挂起已禁用"
echo "✓ 笔记本合盖不会挂起系统"
echo "✓ 系统空闲不会自动挂起"
echo ""
echo "⚠️  注意: 配置将在以下情况后生效："
echo "   1. 重启系统（推荐）"
echo "   2. 重新登录用户会话"
echo ""
echo "如需立即生效，请手动执行: sudo systemctl restart systemd-logind"
echo "（警告: 该命令会强制关闭当前桌面会话）"
