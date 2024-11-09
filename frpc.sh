#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# 字体颜色
Green="\033[32m"
Red="\033[31m"
Yellow="\033[33m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
Font="\033[0m"

# 变量
WORK_PATH=$(dirname $(readlink -f $0))
FRP_NAME=frpc
FRP_VERSION=0.61.0
FRP_PATH=/usr/local/frp
PROXY_URL="https://ghp.ci/"

# 检查 frpc
if [ -f "/usr/local/frp/${FRP_NAME}" ] || [ -f "/usr/local/frp/${FRP_NAME}.toml" ] || [ -f "/lib/systemd/system/${FRP_NAME}.service" ]; then
    echo -e "${Green}=========================================================================${Font}"
    echo -e "${RedBG}当前已退出脚本.${Font}"
    echo -e "${Green}检查到服务器已安装${Font} ${Red}${FRP_NAME}${Font}"
    echo -e "${Green}请手动确认和删除${Font} ${Red}/usr/local/frp/${Font} ${Green}目录下的${Font} ${Red}${FRP_NAME}${Font} ${Green}和${Font} ${Red}/${FRP_NAME}.toml${Font} ${Green}文件以及${Font} ${Red}/lib/systemd/system/${FRP_NAME}.service${Font} ${Green}文件,再次执行本脚本.${Font}"
    echo -e "${Green}参考命令如下:${Font}"
    echo -e "${Red}rm -rf /usr/local/frp/${FRP_NAME}${Font}"
    echo -e "${Red}rm -rf /usr/local/frp/${FRP_NAME}.toml${Font}"
    echo -e "${Red}rm -rf /lib/systemd/system/${FRP_NAME}.service${Font}"
    echo -e "${Green}=========================================================================${Font}"
    exit 0
fi

# 停止现有 frpc 进程
while ps -A | grep -w ${FRP_NAME} > /dev/null; do
    FRPCPID=$(pgrep -x ${FRP_NAME})
    kill "$FRPCPID" && sleep 1
done

# 检查包管理
if type apt-get >/dev/null 2>&1; then
    apt-get install -y wget curl
elif type yum >/dev/null 2>&1; then
    yum install -y wget curl
fi

# 检查网络可用性
GOOGLE_HTTP_CODE=$(curl -o /dev/null --connect-timeout 5 --max-time 8 -s --head -w "%{http_code}" "https://www.google.com")
PROXY_HTTP_CODE=$(curl -o /dev/null --connect-timeout 5 --max-time 8 -s --head -w "%{http_code}" "${PROXY_URL}")

# 检查架构
case $(uname -m) in
    x86_64) PLATFORM=amd64 ;;
    aarch64) PLATFORM=arm64 ;;
    armv7|armv7l|armhf) PLATFORM=arm ;;
    *) echo -e "${Red}不支持的架构.${Font}" && exit 1 ;;
esac

FILE_NAME=frp_${FRP_VERSION}_linux_${PLATFORM}

# 下载 FRP
if [ $GOOGLE_HTTP_CODE == "200" ]; then
    wget -P ${WORK_PATH} "https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/${FILE_NAME}.tar.gz" -O "${FILE_NAME}.tar.gz" || {
        echo -e "${Red}从 GitHub 下载失败.${Font}"
        exit 1
    }
else
    if [ $PROXY_HTTP_CODE == "200" ]; then
        wget -P ${WORK_PATH} "${PROXY_URL}https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/${FILE_NAME}.tar.gz" -O "${FILE_NAME}.tar.gz" || {
            echo -e "${Red}从代理下载失败.${Font}"
            exit 1
        }
    else
        echo -e "${Red}检测 GitHub Proxy 代理失效，开始使用官方地址下载${Font}"
        wget -P ${WORK_PATH} "https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/${FILE_NAME}.tar.gz" -O "${FILE_NAME}.tar.gz" || {
            echo -e "${Red}从官方地址下载失败.${Font}"
            exit 1
        }
    fi
fi

tar -zxvf "${FILE_NAME}.tar.gz"

mkdir -p ${FRP_PATH}
mv ${FILE_NAME}/${FRP_NAME} ${FRP_PATH}

# 生成服务名称
CURRENT_DATE=$(date +%m%d)
RANDOM_SUFFIX=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 2)
SERVICE_NAME="${CURRENT_DATE}${RANDOM_SUFFIX}"

# 生成随机 remote_port（范围：3000到6000）
REMOTE_PORT_SSH=$((RANDOM % 3001 + 3000))

# FRP 配置文件路径
FRP_CONFIG_FILE="/usr/local/frp/frpc.toml"

# 创建或更新 FRP 配置文件
cat <<EOL > "$FRP_CONFIG_FILE"
serverAddr = "frps.tzishue.tk"
serverPort = 7000
auth.method = "token"
auth.token = "12345"

[[proxies]]
name = "print-ssh-$SERVICE_NAME"
type = "tcp"
localIP = "127.0.0.1"
localPort = 22
remotePort = $REMOTE_PORT_SSH

[[proxies]]
name = "print-web-$SERVICE_NAME"
type = "http"
localIP = "127.0.0.1"
localPort = 80
subdomain = "nas-$SERVICE_NAME"
# 如果你有自己的域名，可以同时打开这行，你的域名要解析到frps服务器
# customDomains = ["hinas.yourdomain.com"]
EOL

# 配置 systemd
cat >/lib/systemd/system/${FRP_NAME}.service <<EOF
[Unit]
Description=Frp Client Service
After=network.target syslog.target
Wants=network.target

[Service]
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/frp/${FRP_NAME} -c ${FRP_CONFIG_FILE}

[Install]
WantedBy=multi-user.target
EOF

# 完成安装
systemctl daemon-reload
sudo systemctl start ${FRP_NAME}
sudo systemctl enable ${FRP_NAME}

# 清理
rm -rf "${WORK_PATH}/${FILE_NAME}.tar.gz" "${WORK_PATH}/${FILE_NAME}" "${WORK_PATH}/${FRP_NAME}_linux_install.sh"

echo -e "${Green}====================================================================${Font}"
echo -e "${Green}安装成功，请先修改 ${FRP_CONFIG_FILE} 文件，确保格式及配置正确无误!${Font}"
echo -e "${Red}vi ${FRP_CONFIG_FILE}${Font}"
echo -e "${Green}修改完毕后执行以下命令重启服务:${Font}"
echo -e "${Red}sudo systemctl restart ${FRP_NAME}${Font}"
echo -e "${Green}====================================================================${Font}"
