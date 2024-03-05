#!/bin/bash
set -u
#
#*******************************
#Author: hxh
#email: linux.hxh@outlook.com
#Date: 2023-09-01
#FileName:a.sh
#URL: http://www.mshare.top
#Description: 扫描局域网在线主机ip
#Copyright (C): 2023 ALl rights reserved
#*******************************

echo "请输入本机局域网主机网段"
echo "格式如:192.168.0."
read -p "本机主机网段为:" LIP

for i in {1..255};do
    {
    ping -c1 -W1 ${LIP}$i &>/dev/null && echo "${LIP}$i is up" || echo "$LIP$i is down"
    }&
done
wait