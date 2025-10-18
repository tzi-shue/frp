#!/bin/bash

# 安装 CUPS
apt-get update
apt-get install -y cups
apt install -y printer-driver-gutenprint
apt-get install -y printer-driver-splix
apt-get install -y hplip
mkdir hp
cd hp
wget https://www.openprinting.org/download/printdriver/auxfiles/HP/plugins/hplip-3.20.3-plugin.run
wget https://www.openprinting.org/download/printdriver/auxfiles/HP/plugins/hplip-3.20.3-plugin.run.asc
wget https://www.openprinting.org/download/printdriver/auxfiles/HP/plugins/hp_laserjet_1020.plugin
sudo hp-plugin -p
apt-get install foomatic-db-engine
apt-get install printer-driver-gutenprint

# 允许远程访问 CUPS
cupsctl --remote-any
