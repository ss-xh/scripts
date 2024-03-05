#!/bin/bash

GREEN_COLOR='\E[1;32m'
RES='\E[0m'

# 1.查看系统信息
query_system_hardware_info(){

    echo "CPU信息:"
    os_version=$(cat /etc/redhat-release)
    echo -e "${GREEN_COLOR}操作系统: ${os_version}${RES}"

    cpu_architecture=$(lscpu | awk 'NR==1{print $2}')
    echo -e "${GREEN_COLOR}CPU架构: ${cpu_architecture}${RES}"

    cpu_core_conut=$(lscpu | awk 'NR==1{print $2}')
    echo -e "${GREEN_COLOR}CPU核心数量: ${cpu_core_conut}${RES}"

    cpu_thread_conut=$(lscpu | grep -E "^Thread" | tr -s " " |awk -F ':' '{print $2}')
    echo -e "${GREEN_COLOR}CPU每个内核对应线程数: ${cpu_thread_conut}${RES}"

    cpu_info=$(lscpu | grep -E "^Model " | tr -s " " |awk -F ':' '{print $2}')
    echo -e "${GREEN_COLOR}CPU型号信息: ${cpu_info}${RES}"

    echo ; echo
    echo "内存信息:"
    free -h

    echo ; echo
    echo "硬盘信息:"
    df -h | grep -E "^\/dev\/" | awk 'BEGIN{print "Filesystem","Size","Used","Avail","Use%","Mounted"}{printf "%s | %s | %s | %s | %s | %s\n", $1,$2,$3,$4,$5,$6}'

}




# 2.远程主机通过tcp,udp协议与本机建立连接的数量的统计 
query_ss_connect_count(){
ss -ntu | grep -e "^tcp" -e "udp" | awk -F ' +|:' '{print $7}' | sort | uniq -c | sort -nr  
}



# 3.本机网络实时监控
monitor_net_speed(){

read -p "请输入监控的网卡名,默认为eth0:" net_name
# 列出所有网卡的名字
net_names=$((ip addr show) | grep -E "^[0-9]"|awk -F ':' '{print $2}'|tr -d " ")

while :; do
    for name in ${net_names};do
        if [[ $name == ${net_name} ]];then
            break 2
        fi
    done
    net_name=eth0
    break
done

echo "网卡名为:"${net_name}

while : ;do
    oldRece=$(cat /proc/net/dev | grep -e ${net_name}: | awk '{print$2}')
    oldTran=$(cat /proc/net/dev | grep -e ${net_name}: | awk '{print$(NF-7)}')

    sleep 1

    newRece=$(cat /proc/net/dev | grep -e ${net_name}: | awk '{print$2}')
    newTran=$(cat /proc/net/dev | grep -e ${net_name}: | awk '{print$(NF-7)}')

    download=$(( ($newRece - $oldRece)/1024 ))
    upload=$(( ($newTran - $oldTran)/1024 ))
    echo "网卡实时下载速度:${download}KB/s,上传速度 ${upload}KB/s"
done
}
