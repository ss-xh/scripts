#!/bin/bash

#
#*******************************
#Author: hxh
#email: linux.hxh@outlook.com
#Date: 2023-09-01
#FileName:check_ssd_capacity.sh
#URL: http://www.mshare.top
#Description:检查磁盘容量
#Copyright (C):2023 ALl rights reserved
#*******************************

set -u
RED_COLOR='\E[1;31m'
RES='\E[0m'

while :;do
    df -h | grep "^/dev/" | awk -F ' +|%' '{print $5}'
    for ssd_used in `df -h | grep "^/dev/" | awk -F ' +|%' '{print $5}'`;do
        if [[ $ssd_used -gt 5 ]];then
            echo -e "${RED_COLOR} 服务器:`hostname -i` 磁盘容量告急,请马上处理! ${RES}"
        fi
    done
sleep 3
done