#!/bin/bash

# 修改 /etc/hosts 文件
echo "127.0.1.1 print" >> /etc/hosts

# 修改 /etc/hostname 文件
sed -i 's/hi3798mv100/print/' /etc/hostname

# 修改 index.php 和 home.php 中的内容
sed -i 's/海纳斯系统/print/g' /var/www/html/index.php
sed -i 's/海纳斯系统/print/g' /var/www/html/home.php
sed -i 's/海纳斯交流论坛/print/g' /var/www/html/index.php
sed -i 's/海纳斯交流论坛/print/g' /var/www/html/home.php

# 获取设备的 MAC 地址
MAC_ADDRESS=$(cat /sys/class/net/eth0/address)

# 创建 interfaces.d 目录（如果不存在）
mkdir -p /etc/network/interfaces.d

# 写入配置到 /etc/network/interfaces.d/eth0
cat <<EOL > /etc/network/interfaces.d/eth0
auto eth0
iface eth0 inet dhcp
pre-up ifconfig eth0 hw ether $MAC_ADDRESS
EOL

# 一键安装 frpc
wget https://ghp.ci/https://raw.githubusercontent.com/tzi-shue/frp/refs/heads/main/frpc.sh
chmod +x frpc.sh
./frpc.sh

# 安装 CUPS
apt-get update
apt-get install -y cups
apt install -y printer-driver-gutenprint
apt-get install -y printer-driver-splix
apt-get install -y hplip

# 允许远程访问 CUPS
cupsctl --remote-any

echo "所有操作完成！"
