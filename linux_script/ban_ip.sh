#!/bin/bash
#*******************************
#Author: hxh
#email: linux.hxh@outlook.com
#Date: 2023-09-24
#FileName:ban_ip.sh
#URL: http://www.mshare.top
#Description:自定义防SSH密码爆破脚本
#Copyright (C):2023 ALl rights reserved
#*******************************

[[ `id -u` != 0 ]] && echo "请使用root用户执行此脚本" && exit 1

lastb | head -n-2 | awk '{print $3}' | sort | uniq -c > ./lastb.txt

for deny_ip in `awk '{if($1>=3)print $2}' ./lastb.txt`;do

    # 需要判断该IP是否已经被封禁过
    iptables --list -n | grep DROP | awk '{print $4}' | grep ${deny_ip} &>/dev/null
    if [[ $? != 0 ]];then
        # 如果iptables没有该IP封禁记录,就封禁该IP
        iptables -t filter -I INPUT -s ${deny_ip} -j DROP &>/dev/null
    fi
done
# 封禁完毕后,清空登录失败记录,避免重复查询
echo > /var/log/btmp

# 给这个脚本设置定时任务
# chmod +x /home/my_script/ban_ip.sh
# */10 * * * * /home/my_script/ban_ip.sh