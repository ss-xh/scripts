#!/bin/bash

set -e

PYTHON_BASEDIR=/apps/python310
OPENSSL_BASEDIR=/apps/openssl

[[ `id -u` != 0 ]] && echo "请使用root用户执行此脚本" && exit 1
yum install -y gcc gcc-c++ zlib-devel bzip2-devel openssl-devel  sqlite-devel readline-devel ncurses-devel tk-devel xz-devel gdbm-devel libffi-devel

check_commond(){
	if [[ $? != 0 ]];then
		echo "$1 执行失败" && exit 1
	 else
	 	echo "$1 执行成功" 
	 fi
}

install_openssl(){
	cd /usr/local/src
	[[ -f ./openssl-OpenSSL_1_1_1d.tar.gz ]] || wget https://github.com/openssl/openssl/archive/OpenSSL_1_1_1d.tar.gz
	check_commond "下载openssl1.1.1d"

	tar -zxvf openssl-OpenSSL_1_1_1d.tar.gz
	cd openssl-OpenSSL_1_1_1d

	if [[  -d ${OPENSSL_BASEDIR} ]];then
		echo "OpenSSL_1_1_1d 已安装" && return
	else
		mkdir -p ${OPENSSL_BASEDIR}
	fi

	./config --prefix=${OPENSSL_BASEDIR}
	check_commond "编译安装openssl1.1.1d"
	make -j 2 && make install

	mv /usr/bin/openssl /usr/bin/openssl.old
	mv /usr/lib64/openssl /usr/lib64/openssl.old
	mv /usr/lib64/libssl.so /usr/lib64/libssl.so.old
	ln -s ${OPENSSL_BASEDIR}/bin/openssl /usr/bin/openssl
	ln -s ${OPENSSL_BASEDIR}/include/openssl /usr/include/openssl
	ln -s ${OPENSSL_BASEDIR}/lib/libssl.so /usr/lib64/libssl.so
	echo "${OPENSSL_BASEDIR}/lib" >> /etc/ld.so.conf
	ldconfig -v

}


install_python(){

	cd /usr/local/src
	[[ -f Python-3.10.13.tgz ]] || wget https://www.python.org/ftp/python/3.10.13/Python-3.10.13.tgz
	check_commond "下载python"

	if [[  -d ${PYTHON_BASEDIR} ]];then
		echo "Python-3.10.13 已安装"
		exit 1
	else
		mkdir -p ${PYTHON_BASEDIR}
	fi
	
	echo "编译安装Python-3.10.13"
	tar -zxvf Python-3.10.13.tgz
	cd Python-3.10.13
	./configure --prefix=${PYTHON_BASEDIR} --with-openssl=${OPENSSL_BASEDIR}
	make -j 2 && make install
	check_commond "安装python"

	ln -sv ${PYTHON_BASEDIR}/bin/python3 /usr/bin/
	ln -sv ${PYTHON_BASEDIR}/bin/pip3 /usr/bin/

	pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple/

}

main(){
	install_openssl
	install_python
}
main