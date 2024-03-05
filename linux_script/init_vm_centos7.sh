#!/bin/bash

# centos7 初始化

[[ `id -u` != 0 ]] && echo "请使用root用户执行此脚本" && exit 1

# 1.更换镜像源
replace_repo(){
	cp -a /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
	
cat > /etc/yum.repos.d/CentOS-Base.repo << "EOF"
# CentOS-Base.repo
#
# The mirror system uses the connecting IP address of the client and the
# update status of each mirror to pick mirrors that are updated to and
# geographically close to the client.  You should use this for CentOS updates
# unless you are manually picking other mirrors.
#
# If the mirrorlist= does not work for you, as a fall back you can try the 
# remarked out baseurl= line instead.
#
#
 
[base]
name=CentOS-$releasever - Base - repo.huaweicloud.com
baseurl=https://repo.huaweicloud.com/centos/$releasever/os/$basearch/
#mirrorlist=https://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=os
gpgcheck=1
gpgkey=https://repo.huaweicloud.com/centos/RPM-GPG-KEY-CentOS-7
 
#released updates 
[updates]
name=CentOS-$releasever - Updates - repo.huaweicloud.com
baseurl=https://repo.huaweicloud.com/centos/$releasever/updates/$basearch/
#mirrorlist=https://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=updates
gpgcheck=1
gpgkey=https://repo.huaweicloud.com/centos/RPM-GPG-KEY-CentOS-7
 
#additional packages that may be useful
[extras]
name=CentOS-$releasever - Extras - repo.huaweicloud.com
baseurl=https://repo.huaweicloud.com/centos/$releasever/extras/$basearch/
#mirrorlist=https://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=extras
gpgcheck=1
gpgkey=https://repo.huaweicloud.com/centos/RPM-GPG-KEY-CentOS-7
 
#additional packages that extend functionality of existing packages
[centosplus]
name=CentOS-$releasever - Plus - repo.huaweicloud.com
baseurl=https://repo.huaweicloud.com/centos/$releasever/centosplus/$basearch/
#mirrorlist=https://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=centosplus
gpgcheck=1
enabled=0
gpgkey=https://repo.huaweicloud.com/centos/RPM-GPG-KEY-CentOS-7
EOF

	yum clean all && yum makecache
	yum -y install epel-release
	echo "更换镜像源完成"

}

# 2.初始化软件安装
install_init_software(){
    yum -y install gcc make gcc-c++ glibc glibc-devel pcre pcre-devel
    yum -y  install openssl openssl-devel systemd-devel zlib-devel vim lrzsz tree tmux 
    yum -y install lsof tcpdump wget net-tools bc bzip2 zip unzip nfs-utils man-pages 
    yum -y install expect mlocate openssh-server pstree iftop iotop dstat 
    yum -y install traceroute rsync iptables-services fuse-sshfs 
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
set nu
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

cat > ~/.bashrc << EOF
# .bashrc

# User specific aliases and functions

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# user_custom_alias
#----------------------
alias cls='clear'
alias vi='vim'
alias hc='history -c'
alias ll='ls -l'
alias syc='systemctl'
alias iptl='iptables --list -n --line-number'
alias cdnet='cd /etc/sysconfig/network-scripts'
alias cdservice='cd /usr/lib/systemd/system/'
alias cdnginx='cd /apps/nginx/conf'

alias pip='pip3'
alias python='python3'
#----------------------

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi
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