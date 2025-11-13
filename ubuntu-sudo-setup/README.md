# Ubuntu 用户免 Sudo 配置

## 一条命令执行（推荐）

将当前用户加入 sudo 组并配置免密码 sudo：

```bash
sudo sh -c 'usermod -aG sudo $SUDO_USER && echo "$SUDO_USER ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/$SUDO_USER > /dev/null && chmod 0440 /etc/sudoers.d/$SUDO_USER && echo "✓ 配置完成！用户 $SUDO_USER 已加入 sudo 组并配置免密码 sudo。请重新登录生效。"'
```

## 指定用户名执行

将指定用户（例如 `username`）配置免 sudo：

```bash
sudo sh -c 'USERNAME=username && usermod -aG sudo $USERNAME && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/$USERNAME > /dev/null && chmod 0440 /etc/sudoers.d/$USERNAME && echo "✓ 配置完成！用户 $USERNAME 已加入 sudo 组并配置免密码 sudo。请重新登录生效。"'
```

## 使用脚本文件

```bash
sudo bash setup-sudo.sh [username]
```

如果不指定用户名，默认使用当前用户。

## 配置说明

此命令做了以下操作：

1. **usermod -aG sudo $USER** - 将用户加入 sudo 组
2. **echo "..." | tee /etc/sudoers.d/$USER** - 创建用户专属的 sudoers 配置文件，允许免密码 sudo
3. **chmod 0440** - 设置正确的文件权限（必需）
4. 配置完成后需要**重新登录**才能生效

## 验证配置

重新登录后，执行以下命令验证：

```bash
sudo -l
```

应该看到类似输出：
```
User username may run the following commands on hostname:
    (ALL) NOPASSWD: ALL
```

## 安全提示

⚠️ **警告**：配置 NOPASSWD 会降低系统安全性，仅在可信环境下使用（如开发环境、个人虚拟机等）。生产服务器请谨慎使用。

---

# 一键安装配置 net-tools 和 SSH

## 一条命令执行（推荐）

安装 net-tools、SSH 服务，并配置 SSH 开机自启动：

```bash
sudo sh -c 'apt-get update -qq && apt-get install -y net-tools openssh-server && systemctl start ssh && systemctl enable ssh && echo "✓ 配置完成！net-tools 和 SSH 服务已安装并启动，SSH 已设置为开机自启动" && systemctl status ssh --no-pager'
```

## 使用脚本文件

```bash
sudo bash setup-network-ssh.sh
```

## 配置说明

此命令做了以下操作：

1. **apt-get update** - 更新软件包列表
2. **apt-get install -y net-tools openssh-server** - 安装 net-tools 和 SSH 服务
3. **systemctl start ssh** - 启动 SSH 服务
4. **systemctl enable ssh** - 设置 SSH 开机自启动
5. **systemctl status ssh** - 显示 SSH 服务状态

## 验证配置

检查 SSH 服务状态：
```bash
systemctl status ssh
```

测试 net-tools 命令：
```bash
ifconfig
netstat -tuln
```

查看 SSH 是否开机自启：
```bash
systemctl is-enabled ssh
```

## 远程连接

配置完成后可以使用 SSH 远程连接：
```bash
ssh username@server_ip
```

---

# Ubuntu Desktop 性能模式配置（禁用休眠睡眠）

## 一条命令执行（推荐）

### 完整版本（包含桌面环境设置）

禁用休眠、睡眠、挂起等电源管理功能，使 Ubuntu Desktop 保持与 Server 版本一样的性能模式：

```bash
sudo sh -c 'systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target && sed -i.bak "s/#HandleLidSwitch=.*/HandleLidSwitch=ignore/;s/#HandleLidSwitchExternalPower=.*/HandleLidSwitchExternalPower=ignore/;s/#IdleAction=.*/IdleAction=ignore/" /etc/systemd/logind.conf && grep -q "^HandleLidSwitch=" /etc/systemd/logind.conf || echo "HandleLidSwitch=ignore" >> /etc/systemd/logind.conf && grep -q "^HandleLidSwitchExternalPower=" /etc/systemd/logind.conf || echo "HandleLidSwitchExternalPower=ignore" >> /etc/systemd/logind.conf && grep -q "^IdleAction=" /etc/systemd/logind.conf || echo "IdleAction=ignore" >> /etc/systemd/logind.conf && systemctl restart systemd-logind && echo "✓ 性能模式配置完成！休眠、睡眠已禁用，系统将保持持续运行"'
```

### 精简版本（仅系统级设置，不含桌面环境）

只禁用系统级别的休眠/睡眠/挂起功能，配置笔记本合盖不挂起：

```bash
sudo sh -c 'systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target && cp /etc/systemd/logind.conf /etc/systemd/logind.conf.bak && sed -i "s/^#*HandleLidSwitch=.*/HandleLidSwitch=ignore/; s/^#*HandleLidSwitchExternalPower=.*/HandleLidSwitchExternalPower=ignore/; s/^#*IdleAction=.*/IdleAction=ignore/" /etc/systemd/logind.conf && (grep -q "^HandleLidSwitch=" /etc/systemd/logind.conf || echo "HandleLidSwitch=ignore" >> /etc/systemd/logind.conf) && (grep -q "^HandleLidSwitchExternalPower=" /etc/systemd/logind.conf || echo "HandleLidSwitchExternalPower=ignore" >> /etc/systemd/logind.conf) && (grep -q "^IdleAction=" /etc/systemd/logind.conf || echo "IdleAction=ignore" >> /etc/systemd/logind.conf) && echo "✓ 系统级电源管理已禁用，配置将在重启或重新登录后生效"'
```

⚠️ **注意**：配置完成后需要**重启系统**或**重新登录**才能完全生效。

如果想让配置立即生效但会**强制重新登录**（桌面会关闭），使用以下命令：

```bash
sudo sh -c 'systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target && cp /etc/systemd/logind.conf /etc/systemd/logind.conf.bak && sed -i "s/^#*HandleLidSwitch=.*/HandleLidSwitch=ignore/; s/^#*HandleLidSwitchExternalPower=.*/HandleLidSwitchExternalPower=ignore/; s/^#*IdleAction=.*/IdleAction=ignore/" /etc/systemd/logind.conf && (grep -q "^HandleLidSwitch=" /etc/systemd/logind.conf || echo "HandleLidSwitch=ignore" >> /etc/systemd/logind.conf) && (grep -q "^HandleLidSwitchExternalPower=" /etc/systemd/logind.conf || echo "HandleLidSwitchExternalPower=ignore" >> /etc/systemd/logind.conf) && (grep -q "^IdleAction=" /etc/systemd/logind.conf || echo "IdleAction=ignore" >> /etc/systemd/logind.conf) && systemctl restart systemd-logind && echo "✓ 系统级电源管理已禁用"'
```

## 使用脚本文件

```bash
sudo bash setup-performance-mode.sh
```

脚本包含更完整的配置，还会禁用 GNOME 桌面环境的电源管理和屏幕保护。

## 配置说明

此命令做了以下操作：

1. **systemctl mask** - 禁用系统休眠、睡眠、挂起、混合睡眠目标
2. **修改 /etc/systemd/logind.conf** - 配置笔记本合盖不挂起，系统空闲不挂起
3. **systemctl restart systemd-logind** - 重启登录管理服务使配置生效
4. **禁用 GNOME 电源管理**（脚本版本） - 禁用桌面环境的自动挂起
5. **禁用屏幕保护**（脚本版本） - 禁用自动锁屏

## 验证配置

检查休眠睡眠是否已禁用：
```bash
systemctl status sleep.target
systemctl status suspend.target
systemctl status hibernate.target
```

查看 logind 配置：
```bash
grep -E "HandleLidSwitch|IdleAction" /etc/systemd/logind.conf
```

查看 GNOME 电源设置（如果使用 GNOME 桌面）：
```bash
gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type
gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type
```

## 仅恢复桌面屏幕保护和自动锁屏

如果只想恢复桌面环境的屏幕保护和自动锁屏（保持系统级休眠/睡眠禁用）：

```bash
sh -c 'CURRENT_USER="${SUDO_USER:-$USER}"; CURRENT_USER_ID=$(id -u "$CURRENT_USER"); if [ -n "$DBUS_SESSION_BUS_ADDRESS" ]; then gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type suspend && gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type suspend && gsettings set org.gnome.desktop.session idle-delay 300 && gsettings set org.gnome.desktop.screensaver lock-enabled true && gsettings set org.gnome.desktop.screensaver idle-activation-enabled true; else sudo -u "$CURRENT_USER" DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$CURRENT_USER_ID/bus sh -c "gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type suspend && gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type suspend && gsettings set org.gnome.desktop.session idle-delay 300 && gsettings set org.gnome.desktop.screensaver lock-enabled true && gsettings set org.gnome.desktop.screensaver idle-activation-enabled true"; fi && echo "✓ 屏幕保护和自动锁屏已恢复"'
```

或使用脚本文件：
```bash
bash restore-screensaver.sh
```

此命令会：
- 恢复桌面电源管理（5 分钟后挂起）
- 启用屏幕保护
- 启用自动锁屏
- **不影响**系统级的休眠/睡眠禁用状态

## 完全恢复默认电源管理

如果需要完全恢复所有电源管理设置（包括系统级休眠/睡眠）：

```bash
sudo systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target
sudo mv /etc/systemd/logind.conf.backup /etc/systemd/logind.conf
sudo systemctl restart systemd-logind
```

然后再运行上面的命令恢复桌面屏幕保护。

## 使用场景

适用于以下场景：
- 服务器型桌面系统（需要 7x24 小时运行）
- 开发测试环境（防止自动休眠导致服务中断）
- 远程桌面服务器（防止休眠后无法连接）
- 笔记本作为服务器使用（合盖不挂起）
