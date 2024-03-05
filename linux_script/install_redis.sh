#!/bin/bash
ck_ok()
{
        if [ $? -ne 0 ]
        then
                echo "$1 error."
                exit 1
        fi
}


download_redis()
{
    cd /usr/local/src
    if [ -f redis-7.0.4.tar.gz ]
    then
        echo "当前目录已存在redis-7.0.4.tar.gz"
        echo "检测MD5"
        file_md5=`md5sum redis-7.0.4.tar.gz | awk '{print $1}'`
        if [ ${file_md5} == '3a2ce76ef8f5ca3cc6463c487f2d532c' ]
        then
            return 0
        else
            echo "file redis-7.0.4.tar.gz md5 check failed"
            /bin/mv redis-7.0.4.tar.gz redis-7.0.4.tar.gz.old
        fi
    fi
    sudo wget -O redis-7.0.4.tar.gz  https://codeload.github.com/redis/redis/tar.gz/refs/tags/7.0.4
    ck_ok "下载redis"
}


install_redis()
{
    cd /usr/local/src
    sudo tar zxf redis-7.0.4.tar.gz
    ck_ok "解压redis源码包"
    cd redis-7.0.4/
    sudo make && sudo make PREFIX=/usr/local/redis install
    ck_ok "编译和安装redis"


    sudo mkdir -p /usr/local/redis/{conf,log}
    sudo mkdir -p /data/redis
    if id redis &>/dev/null
    then
            echo "系统已经存在redis用户，跳过创建"
    else
            echo "创建redis用户"
            sudo useradd -s /sbin/nologin  redis
    fi
    ck_ok "创建redis用户"
    sudo chown -R redis /data/redis /usr/local/redis/log
}


config_redis()
{
    echo "配置redis.conf"
    sudo /bin/cp /usr/local/src/redis-7.0.4/redis.conf /usr/local/redis/conf/redis.conf
    sudo sed -i 's/daemonize no/daemonize yes/' /usr/local/redis/conf/redis.conf
    sudo sed -i 's@logfile ""@logfile "/usr/local/redis/log/redis.log"@' /usr/local/redis/conf/redis.conf
    sudo sed -i 's@dir ./@dir /data/redis@' /usr/local/redis/conf/redis.conf
    sudo sed -i 's@pidfile /var/run/redis_6379.pid@pidfile /usr/local/redis/log/redis_6379.pid@' /usr/local/redis/conf/redis.conf
    sudo sed -i '/# requirepass foobared/a requirepass 123456' /usr/local/redis/conf/redis.conf


    echo "配置systemd service"
    cat >/tmp/redis.service <<EOF
[Unit]
Description=redis
After=network.target
[Service]
User=redis
Type=forking
TimeoutSec=0
PIDFile=/usr/local/redis/log/redis_6379.pid
ExecStart=/usr/local/redis/bin/redis-server /usr/local/redis/conf/redis.conf
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true
[Install]
WantedBy=multi-user.target
EOF

    sudo /bin/mv /tmp/redis.service /lib/systemd/system/redis.service


    echo "更新内核参数"
    grep -q 'net.core.somaxconn = 2048' /etc/sysctl.conf || echo "net.core.somaxconn = 2048" |sudo tee -a /etc/sysctl.conf
    grep -q 'vm.overcommit_memory = 1' /etc/sysctl.conf || echo "vm.overcommit_memory = 1" |sudo tee -a  /etc/sysctl.conf
    sudo sysctl -p
    sudo systemctl daemon-reload
    sudo systemctl enable redis
    echo "启动redis服务"
    sudo systemctl start redis
    ck_ok "启动redis服务"
}

download_redis
install_redis
config_redis
