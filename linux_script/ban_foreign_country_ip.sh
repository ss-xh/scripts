#!/bin/bash
#
#*******************************
#Author: hxh
#email: linux.hxh@outlook.com
#Date: 2023-10-18
#FileName:a.sh
#URL: http://www.mshare.top
#Description: 服务器禁止国外IP访问
#Copyright (C): 2023 ALl rights reserved
#*******************************

[[ `id -u` != 0 ]] && echo "请使用root用户执行此脚本" && exit 1

ipset create asan hash:net -exist
ipset flush asan

[[ -f "foreign_country_ip.zone" ]] && rm -f foreign_country_ip.zone

echo "国外ip网址查询:https://www.ipdeny.com/ipblocks/"
echo "如美国的ip段集合:https://www.ipdeny.com/ipblocks/data/aggregated/as-aggregated.zone"

read -p "输入指定国国家ip地址结合下载链接:" URL
[[ ! -n $URL ]] && URL="https://www.ipdeny.com/ipblocks/data/aggregated/as-aggregated.zone"
curl -s -o foreign_country_ip.zone $URL
if [[ $? != 0 ]];then
    echo "请检查网络,或者ip下载地址"
    exit 1
fi


for ip in `cat foreign_country_ip.zone`;do
    ipset add asan $ip
done

iptables -A INPUT --match set --match-set asan src -j DROP