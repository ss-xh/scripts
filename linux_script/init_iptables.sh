#!/bin/bash

# iptables初始化设置

[[ `id -u` != 0 ]] && echo "请使用root用户执行此脚本" && exit 1

# 关闭防火墙
systemctl stop firewalld ; systemctl disable firewalld

# 关闭selinux
setenforce 0
[[ -e /etc/selinux/config ]] || cp /etc/selinux/config /etc/selinux/config.backup
sed -Ei 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config

# 安装 iptables-services
yum -y install iptables-service &>/dev/null 

# 修改默认iptables配置文件
[[ -e /etc/sysconfig/iptables.backup ]] || cp /etc/sysconfig/iptables /etc/sysconfig/iptables.backup

cat > /etc/sysconfig/iptables <<"EOF"
*filter
:INPUT DROP [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -i lo -j ACCEPT
-A INPUT -p tcp -m multiport --dport 20,21,22,23,25,80,443,3690,9527 -j ACCEPT
-A INPUT -p udp -m multiport --dport 53 -j ACCEPT
COMMIT

EOF

systemctl restart iptables.service && systemctl enable iptables.service

# 防止ssh登录失败,3分钟后,清除规则
#----------------- 测试登录无误后请删除以下代码,重新执行脚本
sleep 180
cat /etc/sysconfig/iptables.backup > /etc/sysconfig/iptables
iptables -F ; iptables -X ; iptables -Z
systemctl restart iptables.service && systemctl enable iptables.service
#-----------------


