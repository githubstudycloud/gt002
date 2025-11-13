#!/bin/bash
# Ubuntu Desktop 性能模式配置脚本
# 禁用休眠、睡眠、挂起等电源管理功能，保持系统持续运行
# 使用方法: sudo bash setup-performance-mode.sh

echo "开始配置 Ubuntu Desktop 性能模式..."

# 禁用系统休眠和睡眠
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# 配置 systemd-logind 不自动挂起
if [ -f /etc/systemd/logind.conf ]; then
    # 备份原配置文件
    cp /etc/systemd/logind.conf /etc/systemd/logind.conf.backup

    # 修改配置
    sed -i 's/#HandleLidSwitch=.*/HandleLidSwitch=ignore/' /etc/systemd/logind.conf
    sed -i 's/#HandleLidSwitchExternalPower=.*/HandleLidSwitchExternalPower=ignore/' /etc/systemd/logind.conf
    sed -i 's/#IdleAction=.*/IdleAction=ignore/' /etc/systemd/logind.conf

    # 如果配置项不存在，则添加
    grep -q "^HandleLidSwitch=" /etc/systemd/logind.conf || echo "HandleLidSwitch=ignore" >> /etc/systemd/logind.conf
    grep -q "^HandleLidSwitchExternalPower=" /etc/systemd/logind.conf || echo "HandleLidSwitchExternalPower=ignore" >> /etc/systemd/logind.conf
    grep -q "^IdleAction=" /etc/systemd/logind.conf || echo "IdleAction=ignore" >> /etc/systemd/logind.conf

    # 重启 systemd-logind 服务
    systemctl restart systemd-logind
    echo "✓ systemd-logind 配置已更新"
fi

# 禁用 GNOME 桌面环境的自动挂起（如果存在）
if command -v gsettings &> /dev/null; then
    # 获取当前用户（即使用 sudo 的原始用户）
    REAL_USER="${SUDO_USER:-$USER}"
    REAL_USER_ID=$(id -u "$REAL_USER")

    # 以实际用户身份运行 gsettings
    sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$REAL_USER_ID/bus gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing' 2>/dev/null || true
    sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$REAL_USER_ID/bus gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing' 2>/dev/null || true
    sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$REAL_USER_ID/bus gsettings set org.gnome.desktop.session idle-delay 0 2>/dev/null || true

    echo "✓ GNOME 桌面电源管理已禁用"
fi

# 禁用屏幕保护程序自动锁屏（如果存在）
if command -v gsettings &> /dev/null; then
    REAL_USER="${SUDO_USER:-$USER}"
    REAL_USER_ID=$(id -u "$REAL_USER")

    sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$REAL_USER_ID/bus gsettings set org.gnome.desktop.screensaver lock-enabled false 2>/dev/null || true
    sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$REAL_USER_ID/bus gsettings set org.gnome.desktop.screensaver idle-activation-enabled false 2>/dev/null || true

    echo "✓ 屏幕保护和自动锁屏已禁用"
fi

echo ""
echo "=== 配置完成 ==="
echo "✓ 系统休眠、睡眠、挂起已禁用"
echo "✓ 笔记本合盖不会挂起系统"
echo "✓ 系统空闲不会自动挂起"
echo "✓ GNOME 桌面电源管理已禁用（如适用）"
echo "✓ 屏幕保护和自动锁屏已禁用（如适用）"
echo ""
echo "当前电源管理状态:"
systemctl status sleep.target --no-pager 2>/dev/null || echo "sleep.target 已禁用"
echo ""
echo "注意: 部分设置可能需要重启系统或重新登录才能完全生效"
