#!/bin/bash

# 修改 root 用户密码为 password
echo "root:password" | chpasswd

# 修改 ubuntu 用户密码为 hzx0928
echo "ubuntu:hzx0928" | chpasswd

# 修改 /etc/hosts 文件
echo "127.0.1.1 print" >> /etc/hosts

# 修改 /etc/hostname 文件
sed -i 's/hi3798mv100/print/' /etc/hostname

# 修改 index.php 和 home.php 中的内容
sed -i 's/海纳思系统/print/g' /var/www/html/index.php
sed -i 's/海纳思系统/print/g' /var/www/html/home.php
sed -i 's/海纳思交流论坛/print/g' /var/www/html/index.php
sed -i 's/海纳思交流论坛/print/g' /var/www/html/home.php
# 删除指定字符串
sed -i '/忘记密码？ SSH 终端输入 reset-login/d' /var/www/html/index.php

# 检查 frpc.sh 是否存在，如果存在则删除
if [ -f frpc.sh ]; then
    echo "发现旧的 frpc.sh，正在删除..."
    rm frpc.sh
fi

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
