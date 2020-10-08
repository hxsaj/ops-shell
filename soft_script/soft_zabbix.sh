#!/usr/bin/env bash
###################################################################
# Function :CentOS7.X 安装Zabbix 5.0 LTS 版本安装                   #
# Platform :RedHatEL7.x Based Platform                            #
# Version  :1.0                                                   #
# Date     :2020-08-28                                            #
# Author   :mugoLH                                                #
# Contact  :houxiaoshuai@baidu.com & hxsaj@126.com                #
# Company  :                                                      #
# depend on:PHP 7.2 nginx MariaDB或者Mysql5.7版本以上               #
###################################################################

#  导入子函数脚本列表 Import the list of subfunction scripts
########## ########## ########## ########## ########## ########## #
. ../int/int_color_information.sh        # 导入 回显信息的颜色配置 函数                show_notice show_warning show_error
#. ./int/int_back_file_tar.sh            # 导入 备份文件（目录） 函数                  backup_file backup_file_tar
. ../int/int_selinux_firewalld.sh        # 导入 禁用 selinux 和 firewalld 函数       selinux_check_off firewalld_check_off


#  变量定义列表 List of variable definitions
########## ########## ########## ########## ########## ########## #
ali_yuan=https://mirrors.aliyun.com/zabbix/zabbix/5.0/rhel/7/x86_64/zabbix-release-5.0-1.el7.noarch.rpm

yum_from=${ali_yuan}

# yum 安装 Zabbix Server
install_zabbix_server_yum(){
    #  关闭 selinux
    selinux_check_off \
    && show_notice "- 1, ---  关闭 selinux 完成  ----"

    #  关闭 防火墙
    firewalld_check_off \
    && show_notice "- 2, ---  关闭 firewalld 完成  ----"

    #  安装 zabbix 镜像源
	rpm -Uvh ${yum_from} >/dev/null 2>&1 \
    && show_notice "- 3, ---  安装 zabbix 镜像源 完成  ----"

    #  zabbix 源信息修改
	sed -i 's#http://repo.zabbix.com#https://mirrors.aliyun.com/zabbix#' /etc/yum.repos.d/zabbix.repo \
    && show_notice "- 4, ---  zabbix 源信息修改 完成  ----"

    #  清除源元数据，并重建
	yum clean all >/dev/null 2>&1 \
    && show_notice "- 5, ---  清除 yum 源元数据 完成  ----"
    yum makecache >/dev/null 2>&1 \
    && show_notice "- 6, ---  重建 yum 源元数据 完成  ----"

    #  安装 zabbix server（mysql数据库版本） 和 agent......
	yum install zabbix-server-mysql zabbix-agent -y >/dev/null 2>&1 \
    && show_notice "- 7, ---  安装 zabbix-server 和 zabbix agent 完成  ----"

    #  安装 Software Collections，便于后续安装高版本的 php，默认 yum 安装的 php 版本为 5.4 过低......"
	yum install centos-release-scl -y >/dev/null 2>&1 \
    && show_notice "- 8, ---  安装 Software Collections(便于后续安装高版本的 php，默认 yum 安装的 php 版本为 5.4 过低...) 完成  ----"
 
    #  启用 zabbix 前端源，修改vi /etc/yum.repos.d/zabbix.repo，将[zabbix-frontend]下的 enabled 改为 1......
	sed -i "$(grep -A6 -n "zabbix-frontend" /etc/yum.repos.d/zabbix.repo|grep enabled |awk -F "-" '{print$1}')s/enabled=off/enabled=1/" /etc/yum.repos.d/zabbix.repo \
    && show_notice "- 9, ---  启用 zabbix 前端源 完成  ----"

    #  安装 zabbix 前端和相关环境......
	yum install nginx zabbix-web-mysql-scl zabbix-nginx-conf-scl -y >/dev/null 2>&1 \
    && show_notice "- 10, ---  安装 zabbix 前端 完成  ----"
}

# Zabbix Server 数据库构建
init_zabbix_server_db(){
    #  获取数据库root账号密码
    read -p "构建 zabbix 数据库需要使用数据库root账户密码：" db_root_pw

    #  设置 zabbix 数据库密码
    read -p "设置 zabbix 数据库密码(默认用户：zabbix_user)：" zabbix_user_pw

    #  执行构建
    myc="mysql -uroot -p${db_root_pw} -e"
    ${myc} "create database zabbix character set utf8 collate utf8_bin;"
    ${myc} "create user zabbix_user@'%' identified by '${zabbix_user_pw}';"
    ${myc} "grant all privileges on zabbix.* to zabbix@localhost;"

    #  导入 zabbix 初始化数据库脚本 zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -p zabbix
    zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix_user -p${zabbix_user_pw} zabbix

    # 
}
修改 zabbix server 配置文件vi /etc/zabbix/zabbix_server.conf 里的数据库密码
DBPassword=password

修改 zabbix 的 php 配置文件vi /etc/opt/rh/rh-php72/php-fpm.d/zabbix.conf 里的时区，改成 Asia/Shanghai
php_value[date.timezone] = Asia/Shanghai

启动相关服务，并配置开机自动启动
systemctl restart zabbix-server zabbix-agent httpd rh-php72-php-fpm
systemctl enable zabbix-server zabbix-agent httpd rh-php72-php-fpm

使用浏览器访问http://ip/zabbix 即可访问 zabbix 的 web 页面
登录账号为 Admin，密码：zabbix



# docker 安装（阿里源）
Docker-ce_Install_Aliyun(){
	echo "1、docker所依赖的包环境"         && yum install -y yum-utils device-mapper-persistent-data lvm2
	echo "2、Docker-ce 阿里源镜像"        && yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
	echo "3、更新一下yum软件包"            && yum makecache fast
	echo "4、安装docke-ce(默认安装最新版)" && yum -y install docker-ce
	echo "5、启动docker并设置开机启动"     && systemctl enable --now docker.service
	echo "6、添加阿里云docker镜像加速"     && echo '{ "registry-mirrors": ["https://l3rxe7k8.mirror.aliyuncs.com"] }' > /etc/docker/daemon.json
	echo "7、查看docker版本"              && docker version
}



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
