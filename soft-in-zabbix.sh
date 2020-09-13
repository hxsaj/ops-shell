#!/usr/bin/env bash
###################################################################
# Function :CentOS7.X 自动安装cobbler服务器，并实现cobbler-web管理    #
# Platform :RedHatEL7.x Based Platform                            #
# Version  :1.0                                                   #
# Date     :2020-08-28                                            #
# Author   :mugoLH                                                #
# Contact  :houxiaoshuai@baidu.com & hxsaj@126.com                #
# Company  :                                                      #
# depend on: // soft-in.sh // (服务安装目录及自制公共函数库)          #
###################################################################


#  软件函数列表 List of software functions
########## ########## ########## ########## ########## ########## #

# [ ---- Zabbix Server ---- yum 安装
Zabbix_Server_Install_Yum(){
	echo -e "z-1，安装 zabbix 镜像源......"
	rpm -Uvh https://mirrors.aliyun.com/zabbix/zabbix/5.0/rhel/7/x86_64/zabbix-release-5.0-1.el7.noarch.rpm

	echo -e "z-2，将 zabbix 源修改为阿里巴巴源......"
	sed -i 's#http://repo.zabbix.com#https://mirrors.aliyun.com/zabbix#' /etc/yum.repos.d/zabbix.repo

	echo -e "z-3，清除源元数据，并重建......"
	yum clean all && yum makecache

	echo -e "z-4，安装 zabbix server（mysql数据库版本） 和 agent......"
	yum install zabbix-server-mysql zabbix-agent -y

	echo -e "z-5，安装 Software Collections，便于后续安装高版本的 php，默认 yum 安装的 php 版本为 5.4 过低......"
	yum install centos-release-scl -y

	echo -e "z-6，启用 zabbix 前端源，修改vi /etc/yum.repos.d/zabbix.repo，将[zabbix-frontend]下的 enabled 改为 1......"
	sed -i "$(grep -A6 -n "zabbix-frontend" /etc/yum.repos.d/zabbix.repo|grep enabled |awk -F "-" '{print$1}')s/enabled=off/enabled=1/" /etc/yum.repos.d/zabbix.repo

	echo -e "z-7，安装 zabbix 前端和相关环境......"
	yum install zabbix-web-mysql-scl zabbix-apache-conf-scl -y
}

# [ ---- Zabbix Server ---- Docker 安装
Zabbix_Server_Install_Docker(){
	echo "1、安装Docker-MySQL-5.7......"
	docker run --name mysql-server -t \
	-e MYSQL_DATABASE="zabbix" \
	-e MYSQL_USER="zabbix" \
	-e MYSQL_PASSWORD="pangshare.com" \
	-e MYSQL_ROOT_PASSWORD="pangshare.com" \
	-d mysql:5.7 \
	--character-set-server=utf8 \
	--collation-server=utf8_bin

	echo "2、安装Docker-Java Agent......" 
	docker run --name zabbix-java-gateway -t \
	-d zabbix/zabbix-java-gateway:latest

	echo "3、安装Docker-Zabbix......" 
	docker run --name zabbix-server-mysql -t \
	-e DB_SERVER_HOST="mysql-server" \
	-e MYSQL_DATABASE="zabbix" \
	-e MYSQL_USER="zabbix" \
	-e MYSQL_PASSWORD="pangshare.com" \
	-e MYSQL_ROOT_PASSWORD="pangshare.com" \
	-e ZBX_JAVAGATEWAY="zabbix-java-gateway" \
	--link mysql-server:mysql \
	--link zabbix-java-gateway:zabbix-java-gateway \
	-p 10051:10051 \
	-d zabbix/zabbix-server-mysql:latest

	echo "4、安装Docker-Nginx......" 
	docker run --name zabbix-web-nginx-mysql -t \
	-e DB_SERVER_HOST="mysql-server" \
	-e MYSQL_DATABASE="zabbix" \
	-e MYSQL_USER="zabbix" \
	-e MYSQL_PASSWORD="pangshare.com" \
	-e MYSQL_ROOT_PASSWORD="pangshare.com" \
	--link mysql-server:mysql \
	--link zabbix-server-mysql:zabbix-server \
	-p 80:8080 \
	-d zabbix/zabbix-web-nginx-mysql:latest

	echo "5、安装完成！
	浏览器输入：http://“宿主服务器IP地址”/ ，即可登录Zabbix，用户名密码：Admin / zabbix
	"
}

# yum 安装默认的mariadb
MariaDB_Install_Yum(){
	echo -e "db-1，yum 安装 centos7 默认的 mariadb 数据库......"
	yum install mariadb-server -y

	echo -e "db-2，启动数据库，并配置开机自动启动......"
	systemctl enable --now mariadb

	echo -e "db-3，初始化 mariadb 并配置 root 密码......"
	mysql_secure_installation
}

# Zabbix Server数据库新建库
Zabbix_DB_Create(){

	Mysql_Cli="mysql -h${DBServer_Host_Zabbix} -u${DBServer_User_Zabbix} -p${DBServer_Paaswd_Zabbix} -P${DBServer_Port_Zabbix} -sN -e"
	${Mysql_Cli} "create database zabbix character set utf8 collate utf8_bin;"
	${Mysql_Cli} "create user 'zabbix'@'%' identified by 'password';"
	${Mysql_Cli} "grant all privileges on zabbix.* to 'zabbix'@'%';"
	zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -p zabbix


}

create database zabbix character set utf8 collate utf8_bin;
create user zabbix@localhost identified by 'password';
grant all privileges on zabbix.* to zabbix@localhost;
quit;
使用以下命令导入 zabbix 数据库，zabbix 数据库用户为 zabbix，密码为 password

zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -p zabbix
修改 zabbix server 配置文件vi /etc/zabbix/zabbix_server.conf 里的数据库密码

DBPassword=password
修改 zabbix 的 php 配置文件vi /etc/opt/rh/rh-php72/php-fpm.d/zabbix.conf 里的时区，改成 Asia/Shanghai

php_value[date.timezone] = Asia/Shanghai
启动相关服务，并配置开机自动启动

systemctl restart zabbix-server zabbix-agent httpd rh-php72-php-fpm
systemctl enable zabbix-server zabbix-agent httpd rh-php72-php-fpm
使用浏览器访问http://ip/zabbix 即可访问 zabbix 的 web 页面#!/usr/bin/env bash





# 编译安装 Zabbix Server
Compile_Install_Zabbix_Server(){

}

# 编译安装 nginx
Compile_Install_Nginx(){
	echo "1、准备开始安装......"     && sleep 3
	echo "2、添加nginx用户......"   && useradd nginx -s /sbin/nologin
	echo "3、安装依赖包......"      && yum install make gcc gcc-c++ zlib-devel pcre-devel openssl-devel -y
	echo "4、下载nginx源码包......" && wget http://nginx.org/download/nginx-1.18.0.tar.gz && tar -zxf ./nginx-1.18.0.tar.gz
	echo "5、编译......" && cd ./nginx-1.18.0 &&./configure  --user=nginx --group=nginx --prefix=/usr/local/nginx --with-http_stub_status_module --with-http_ssl_module --with-pcre
	echo "6、安装......" && make && make install && echo "恭喜，编译安装完成！"
}
