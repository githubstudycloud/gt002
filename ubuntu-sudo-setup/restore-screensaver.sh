#!/bin/bash
# Ubuntu Desktop 恢复屏幕保护和桌面锁屏
# 使用方法: bash restore-screensaver.sh (不需要 sudo)

echo "开始恢复屏幕保护和桌面锁屏设置..."

# 获取当前用户
CURRENT_USER="${SUDO_USER:-$USER}"
CURRENT_USER_ID=$(id -u "$CURRENT_USER")

# 检查是否有 GNOME 桌面环境
if ! command -v gsettings &> /dev/null; then
    echo "✗ 未检测到 gsettings 命令，可能不是 GNOME 桌面环境"
    exit 1
fi

# 恢复 GNOME 桌面电源管理（使用默认值）
echo "恢复电源管理设置..."
if [ -n "$DBUS_SESSION_BUS_ADDRESS" ]; then
    # 如果已经在用户会话中运行
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'suspend' 2>/dev/null || true
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'suspend' 2>/dev/null || true
    gsettings set org.gnome.desktop.session idle-delay 300 2>/dev/null || true
else
    # 如果使用 sudo 运行
    sudo -u "$CURRENT_USER" DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$CURRENT_USER_ID/bus gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'suspend' 2>/dev/null || true
    sudo -u "$CURRENT_USER" DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$CURRENT_USER_ID/bus gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'suspend' 2>/dev/null || true
    sudo -u "$CURRENT_USER" DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$CURRENT_USER_ID/bus gsettings set org.gnome.desktop.session idle-delay 300 2>/dev/null || true
fi

echo "✓ 电源管理已恢复（交流电和电池模式均设置为 5 分钟后挂起）"

# 恢复屏幕保护程序和自动锁屏
echo "恢复屏幕保护和自动锁屏..."
if [ -n "$DBUS_SESSION_BUS_ADDRESS" ]; then
    gsettings set org.gnome.desktop.screensaver lock-enabled true 2>/dev/null || true
    gsettings set org.gnome.desktop.screensaver idle-activation-enabled true 2>/dev/null || true
else
    sudo -u "$CURRENT_USER" DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$CURRENT_USER_ID/bus gsettings set org.gnome.desktop.screensaver lock-enabled true 2>/dev/null || true
    sudo -u "$CURRENT_USER" DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$CURRENT_USER_ID/bus gsettings set org.gnome.desktop.screensaver idle-activation-enabled true 2>/dev/null || true
fi

echo "✓ 屏幕保护和自动锁屏已启用"

echo ""
echo "=== 恢复完成 ==="
echo "✓ GNOME 桌面电源管理已恢复默认设置"
echo "✓ 屏幕保护和自动锁屏已启用"
echo ""
echo "当前设置:"
echo "---"
if [ -n "$DBUS_SESSION_BUS_ADDRESS" ]; then
    echo "交流电模式休眠设置: $(gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 2>/dev/null)"
    echo "电池模式休眠设置: $(gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 2>/dev/null)"
    echo "空闲延迟: $(gsettings get org.gnome.desktop.session idle-delay 2>/dev/null) 秒"
    echo "自动锁屏: $(gsettings get org.gnome.desktop.screensaver lock-enabled 2>/dev/null)"
else
    sudo -u "$CURRENT_USER" DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$CURRENT_USER_ID/bus bash -c "
        echo '交流电模式休眠设置: '\$(gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 2>/dev/null)
        echo '电池模式休眠设置: '\$(gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 2>/dev/null)
        echo '空闲延迟: '\$(gsettings get org.gnome.desktop.session idle-delay 2>/dev/null)' 秒'
        echo '自动锁屏: '\$(gsettings get org.gnome.desktop.screensaver lock-enabled 2>/dev/null)
    " 2>/dev/null || true
fi
echo ""
echo "注意: 此脚本仅恢复桌面环境的电源管理设置"
echo "      如需恢复系统级休眠/睡眠功能，请查看 README.md 中的完整恢复命令"
