#!/bin/bash

[[ `id -u` != 0 ]] && echo "请使用root用户执行此脚本" && exit 1

cd /usr/local/src

# ==== 设置常量
mysql_url="https://downloads.mysql.com/archives/get/p/23/file/mysql-8.0.33-linux-glibc2.12-x86_64.tar.xz"

mysql_base_dir="/apps/mysql"
mysql_data_dir="/data/mysql"

mysql_root_pwd="root"
# ====

check_commond(){
    if [[ $? != 0 ]];then
        echo "$1 执行失败" && exit 1
    fi
}

download_mysql(){
    if [[ -e mysql-8.0.33-linux-glibc2.12-x86_64.tar.xz ]] ;then
        # mv mysql-8.0.33-linux-glibc2.12-x86_64.tar.xz mysql-8.0.33-linux-glibc2.12-x86_64.tar.xz.backup
        return 
    fi
    wget ${mysql_url}
    check_commond "下载mysql"
}

install_mysql(){
    # -------- 创建mysql用户
    id mysql &>/dev/null
    if [[ $? == 0 ]];then
        echo "系统已经存在mysql用户，跳过创建"
    else
        echo "创建 mysql 系统用户"
        useradd -s /sbin/nologin  mysql
    fi

    # -------- 判断 mysql安装文件夹,数据存放文件夹是否存在
    if [[ -d ${mysql_base_dir} ]];then
        mv ${mysql_base_dir} ${mysql_base_dir}.backup
    fi
    
    if [[ -d ${mysql_data_dir} ]];then
        mv ${mysql_data_dir} ${mysql_data_dir}.backup
    fi
    mkdir -p ${mysql_data_dir}
    chown -R mysql ${mysql_data_dir}
    # -------- 

    # 解压mysq到指定文件夹
    [[ -d /apps ]] || mkdir /apps
    mv mysql-8.0.33-linux-glibc2.12-x86_64.tar.xz /apps
    cd /apps
    tar Jxf mysql-8.0.33-linux-glibc2.12-x86_64.tar.xz
    check_commond "解压mysql"
    mv mysql-8.0.33-linux-glibc2.12-x86_64 mysql
    chown -R mysql ${mysql_base_dir}
    
    

    if [ -f ${mysql_base_dir}/my.cnf ]
    then
        echo "MySQL配置文件已经存在,删除"
        rm -f ${mysql_base_dir}/my.cnf
    fi

echo "设置mysql配置文件"
cat > ${mysql_base_dir}/my.cnf << EOF
[mysqld]
user = mysql
port = 3306
server_id = 1
basedir = ${mysql_base_dir}
datadir = ${mysql_data_dir}
socket = /tmp/mysql.sock
pid-file = ${mysql_data_dir}/mysqld.pid
log-error = ${mysql_data_dir}/mysql.err
EOF

     yum install -y  ncurses-compat-libs  libaio-devel
     check_commond "安装mysql依赖"
     ${mysql_base_dir}/bin/mysqld --console  --datadir=${mysql_data_dir} --initialize-insecure --user=mysql
     check_commond "mysql初始化"

    if [ -f /usr/lib/systemd/system/mysqld.service ];then
        mv  /usr/lib/systemd/system/mysqld.service /usr/lib/systemd/system/mysqld.service.backup
    fi

echo "设置mysql服务"
cat > /usr/lib/systemd/system/mysql.service <<EOF
[Unit]
Description=MYSQL server
After=network.target
[Install]
WantedBy=multi-user.target
[Service]
Type=forking
TimeoutSec=0
PermissionsStartOnly=true
ExecStart=${mysql_base_dir}/bin/mysqld --defaults-file=${mysql_base_dir}/my.cnf --daemonize $OPTIONS
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s TERM $MAINPID
KillMode=process
LimitNOFILE=65535
Restart=on-failure
RestartSec=10
RestartPreventExitStatus=1
PrivateTmp=false
EOF

    systemctl unmask mysql
    systemctl daemon-reload
    systemctl start mysql
    systemctl enable mysql

    ${mysql_base_dir}/bin/mysqladmin -S/tmp/mysql.sock -uroot  password "${mysql_root_pwd}"
    check_commond "设置mysql root用户密码"

    ln -sv ${mysql_base_dir}/bin/mysql /usr/sbin
    ln -sv ${mysql_base_dir}/bin/mysqldump /usr/sbin
    check_commond "创建mysql软链接"

}

download_mysql && install_mysql

echo "
# 允许root用户远程登录操作步骤
1)  mysql -u root -p
2)  use mysql
3)  update user set Host='%' where User='root';
4)  FLUSH PRIVILEGES;
"