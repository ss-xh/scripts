#!/bin/bash

# centos7 初始化

[[ `id -u` != 0 ]] && echo "请使用root用户执行此脚本" && exit 1
cat /etc/redhat-release | grep -i "centos.*7." &>/dev/null
[[ $? != 0 ]] && echo "仅支持centos7" && exit 1

# 1.更换镜像源
replace_repo(){
	wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.huaweicloud.com/repository/conf/CentOS-7-anon.repo
	yum clean all && yum makecache
	echo "更换镜像源完成"

}

# 2.初始化软件安装
install_init_software(){
    yum -y install gcc make gcc-c++ glibc glibc-devel pcre pcre-devel
    yum -y  install openssl openssl-devel systemd-devel zlib-devel vim lrzsz tree tmux 
    yum -y install lsof tcpdump wget net-tools bc bzip2 zip unzip nfs-utils man-pages 
    yum -y install expect mlocate openssh-server pstree iftop iotop dstat 
    yum -y install traceroute rsync iptables-services fuse-sshfs telnet psmisc bind-utils nmap speed-cli
    [[ $? == 0 ]] || echo "初始化软件安装失败,请检查网络" || exit 1

    echo "初始化软件安装完成"
} 

# 3.vim 配置初始化设置
init_vim(){

cat > /etc/profile.d/env.sh << "EOF"
PS1='\[\e[1;36m\] [\u@\h \w]\$\[\e[0m\]'
export EDITOR=vim
EOF

cat > ~/.vimrc << "EOF"
set ignorecase
set cursorline
set autoindent
set nonu
set et
set ts=4
set paste
syntax on
autocmd BufNewFile *.sh exec ":call SetTitle()"
func SetTitle()
        if expand("%:e") == 'sh'
        call setline(1, "#!/bin/bash")
        call setline(2,"#")
        call setline(3, "#*******************************")
        call setline(4, "#Author: hxh")
        call setline(5, "#email: linux.hxh@outlook.com")
        call setline(6, "#Date: ".strftime("%Y-%m-%d"))
        call setline(7,"#FileName:".expand("%"))
        call setline(8,"#URL: http://www.mshare.top")
        call setline(9, "#Description: null")
        call setline(10, "#Copyright (C): ".strftime("%Y") ." ALl rights reserved")
        call setline (11, "#*******************************")
        call setline(12,"")
        endif
endfunc
autocmd BufNewFile * normal G
EOF

}

# 4.命令别名配置
init_bashrc(){

cat >> /etc/profile.d/my_alias.sh << "EOF"
# user_custom_alias
#----------------------
alias cls='clear'
alias vi='vim'
alias hc='history -c'
alias tcpdump='tcpdump -qn'
alias ll='ls -l'
alias syc='systemctl'
alias iptl='iptables --list -n --line-number'
alias cdnet='cd /etc/sysconfig/network-scripts'
alias cdservice='cd /usr/lib/systemd/system/'
alias cdnginx='cd /apps/nginx/conf'

alias pip='pip3'
alias python='python3'
#----------------------

# user_customer_func
#----------------------
into(){
    docker exec -it --privileged  `docker ps | grep "$*" | awk -F ' ' '{print $1}'` bash
}

git_proxy(){
    git config --global http.proxy "http://127.0.0.1:1087"
    git config --global https.proxy "http://127.0.0.1:1087"
}

git_unproxy(){
    git config --global --unset http.proxy
    git config --global --unset https.proxy
}

alias proxy='export all_proxy=http://127.0.0.1:1087'
alias unproxy='unset all_proxy'
#----------------------
EOF

}

# 5.禁用定时任务发送邮件邮件
ban_mail_send(){

    sed -i 's/^MAILTO=root/MAILTO=""/' /etc/crontab 

}

# 6.history 显示用户,日期
history_commond_format(){
    echo 'export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S  `whoami` "' >> /etc/profile
}


# 7.iptables初始化
init_iptables(){
    
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

cat > /etc/sysconfig/iptables << "EOF"
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -i lo -j ACCEPT
-A INPUT -p tcp -m multiport --dport 20,21,22,23,25,80,443,3690,9527 -j ACCEPT
-A INPUT -p udp -m multiport --dport 53 -j ACCEPT
COMMIT

EOF

	systemctl restart iptables.service && systemctl enable iptables.service

}


replace_repo
install_init_software
init_vim
init_bashrc
ban_mail_send
history_commond_format
init_iptables

echo "所有初始化工作完成!!!"
echo "请执行以下命令,重新加载配置文件"
echo "source ~/.bashrc ; source /etc/profile"
