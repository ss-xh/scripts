#!/bin/bash
set -u
#
#*******************************
#Author: hxh
#email: linux.hxh@outlook.com
#Date: 2023 -08 -31
#FileName:rename_all_file_suffix.sh
#URL: http://www.mshare.top
#Description: 统一修改目录下所有文件名后缀
#Copyright (C):2023 ALl rights reserved
#*******************************

RED_COLOR='\E[1;31m'
GREEN_COLOR='\E[1;32m'
RES='\E[0m'

read -p "请输入文件夹全路径:" BASE_DIR

read -p "请输入要修改的后缀名:" SUFFIX

if [[ ! -d "${BASE_DIR}" ]];then
    echo -e "${RED_COLOR} ${BASE_DIR}不是文件夹 ${RES}"
    exit
fi

cat> tempxxxxxxxx.txt<<EOF
${BASE_DIR}
EOF

grep "^\." ./tempxxxxxxxx.txt
if [[ $? == 0 ]] ;then
    echo -e "${RED_COLOR} 请输入绝对路径 ${RES}"
    rm -f ./tempxxxxxxxx.txt
    exit
fi

grep "/$"  ./tempxxxxxxxx.txt
if [[ ! $? == 0 ]] ;then
    echo -e "${RED_COLOR} 路径结尾请带上/ ${RES}"
    rm -f ./tempxxxxxxxx.txt
    exit
fi

for name in `ls ${BASE_DIR}`;do
    prefix_name=$(echo $name | awk -F '.' '{print $1}')
    suffix_name=$(echo $name | awk -F '.' '{print $2}')



    if [[ ${SUFFIX} == ${suffix_name} ]];then
        echo -e "${GREEN_COLOR} $name 无需更改文件后缀名 ${RES}"
        continue
    fi


    OLD_NAME=${prefix_name}.${suffix_name}
    NEW_NAME=${prefix_name}.${SUFFIX}
    mv "${BASE_DIR}${OLD_NAME}" "${BASE_DIR}${NEW_NAME}" &>/dev/null

    if  [[ $? == 0 ]] ; then
        echo -e "${GREEN_COLOR} 成功: ${OLD_NAME} -> ${NEW_NAME} ${RES}"
    else
        echo -e "${RED_COLOR} 失败:  ${OLD_NAME} -> ${NEW_NAME} ${RES}"
    fi
done