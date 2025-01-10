#!/bin/bash

# 安装 CUPS
apt-get update
apt-get install -y cups
apt install -y printer-driver-gutenprint
apt-get install -y printer-driver-splix
apt-get install -y hplip
sudo hp-plugin -i

# 允许远程访问 CUPS
cupsctl --remote-any
