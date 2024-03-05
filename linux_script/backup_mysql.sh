#!/bin/bash

<< "DOC"
1. 备份全部数据库的数据和结构
mysqldump -uroot -p123456 -A > /data/mysqlDump/mydb.sql

2.备份全部数据库的结构（加 -d 参数）
mysqldump -uroot -p123456 -A -d > /data/mysqlDump/mydb.sql

3. 备份全部数据库的数据(加 -t 参数)
mysqldump -uroot -p123456 -A -t > /data/mysqlDump/mydb.sql

4.备份单个数据库的数据和结构(,数据库名mydb)
mysqldump -uroot-p123456 mydb > /data/mysqlDump/mydb.sql

5. 备份单个数据库的结构
mysqldump -uroot -p123456 mydb -d > /data/mysqlDump/mydb.sql

6. 备份单个数据库的数据
mysqldump -uroot -p123456 mydb -t > /data/mysqlDump/mydb.sql

7. 备份多个表的数据和结构（数据，结构的单独备份方法与上同）
mysqldump -uroot -p123456 mydb t1 t2 > /data/mysqlDump/mydb.sql

8. 一次备份多个数据库
mysqldump -uroot -p123456 --databases db1 db2 > /data/mysqlDump/mydb.sql

#==========================================
有两种方式还原，第一种是在 MySQL 命令行中，第二种是使用 SHELL 行完成还原
1. 在系统命令行中，输入如下实现还原：
mysql -uroot -p123456 < /data/mysqlDump/mydb.sql

2. 在登录进入mysql系统中,通过source指令找到对应系统中的文件进行还原：
mysql> source /data/mysqlDump/mydb.sql
DOC


<< "DOC"
参数:
--host -h 服务器IP地址
--port -P 服务器端口号
--user -u MySQL 用户名
--pasword -p MySQL 密码
--databases 指定要备份的数据库
--all-databases 备份mysql服务器上的所有数据库
--compact 压缩模式，产生更少的输出
--comments 添加注释信息
--complete-insert 输出完成的插入语句
--lock-tables 备份前，锁定所有数据库表
--no-create-db/--no-create-info 禁止生成创建数据库语句
--force 当出现错误时仍然继续备份操作
--default-character-set 指定默认字符集
--add-locks 备份数据库表时锁定数据库表
DOC

MYSQL_BACKUP_NAME=backup-`date +%Y%m%d`.sql
MYSQL_BACKUP_PATH=/data/mysqlbackup
MYSQL_USERNAME=root
MYSQL_PASSWORD=root
MYSQL_HOST=127.0.0.1
MYSQL_PORT=3306
REMOTE_MYSQL_HOST=192.168.10.201  # 远程数据库备份,需要提前设置远程服务器的免密登录
REMOTE_MYSQL_PORT=9527

check_commond(){
	[[ $? == 0 ]] || (echo "$1 执行失败" && exit 1)
}

[[ `id -u` != 0 ]] && echo "请使用root用户执行此脚本" && exit 1

backup_mysql() {
	[[ -d ${MYSQL_BACKUP_PATH} ]] || mkdir -p ${MYSQL_BACKUP_PATH}
	if [[ -f ${MYSQL_BACKUP_PATH}/${MYSQL_BACKUP_NAME} ]];then
		mv ${MYSQL_BACKUP_PATH}/${MYSQL_BACKUP_NAME} ${MYSQL_BACKUP_PATH}/${MYSQL_BACKUP_NAME}.backup
	fi
	mysqldump -u${MYSQL_USERNAME} -p${MYSQL_PASSWORD} -h${MYSQL_HOST} -P${MYSQL_PORT} fastapi_test > /data/mysqlbackup/backup-`date +%Y%m%d`.sql
	check_commond "备份数据库至本地" && echo "本地备份成功"

	if [[ -n ${REMOTE_MYSQL_HOST} ]];then
		[[ -n ${REMOTE_MYSQL_PORT} ]] || REMOTE_MYSQL_PORT=22
		scp -r -P${REMOTE_MYSQL_PORT} ${MYSQL_BACKUP_PATH}/${MYSQL_BACKUP_NAME} root@${REMOTE_MYSQL_HOST}:/data
		check_commond "备份数据库至服务器" && echo "远程备份成功"
	fi

}

backup_mysql

echo "
设置定时任务
0 2 * * * /data/mysqlbackup/backup_mysql.sh
"