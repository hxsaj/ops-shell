#!/usr/bin/env bash
#############################
# 内容：Centos7源码安装nginx-1.18.0
# 时间：2020年5月21日 23:03:11
# 作者：mugo老侯
############################

# 1，定义变量及函数
# 1.1 定义变量（软件）
SoftBase="vim lrzsz wget"
SoftMake="pcre-devel pcre gcc gcc-c++ openssl openssl-devel zlib-devel"
NginxDir="/usr/local/nginx"
 
# 1.2 定义变量（编译模块）
ConfigureMoudule="\
--user=www \
--group=www \
--prefix=${NginxDir} \
--with-http_stub_status_module \
--with-http_ssl_module \
--with-http_mp4_module \
--with-http_realip_module \
--with-pcre \
--with-http_gunzip_module \
--with-http_gzip_static_module \
--with-stream"

# 1.3 定义变量（设置和状态）
Netstat_Nginx="netstat -atnlp |grep nginx"
Firewalld_Open_port="--add-port=80/tcp --add-port=443/tcp"


# 1.4 定义函数
#  1.4.1，获取nginx版本列表函数
function NginxVersion_List() {
	curl http://nginx.org/en/download.html|grep -e "tar.gz\""|awk 'BEGIN{i=1}{gsub("href","\n",$0);i++;print}'|grep tar.gz|grep -v asc|awk -F ">|<" '{print$2}'
}
#  1.4.2，安装阿里yum源函数
function Ali_Repo() {
	curl -o etc/yum.repos.d/CentOS-ali.repo https://mirrors.aliyun.com/repo/Centos-7.repo
	yum clean all &&yum makecache
}
#  1.4.3，安装epel yum源函数
function Epel_Repo() {
	wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
	yum clean all &&yum makecache
}

#  1.4.4 关闭SELinux
function Off_Selinux() {
	sed -i "s/"SELINUX=enforcing"/"SELINUX=disabled"/g" /etc/selinux/config
}

#  1.4.5 显示所有可通过防火墙的端口
function List_Open_port() {
	firewall-cmd --zone=public --list-ports
}


###------------------------------###
# 2，开始安装
echo -e "\n\033[1m \033[44;35m 1，编译安装nginx \033[0m"        
echo -e "\n\033[1m \033[44;35m 2，安装基础软件 \033[0m"        &&yum install -y ${SoftBase}
echo -e "\n\033[1m \033[44;35m 3，安装阿里yum源 \033[0m"       &&Ali_Repo
echo -e "\n\033[1m \033[44;35m 4，安装epel源 \033[0m"         &&Epel_Repo
echo -e "\n\033[1m \033[44;35m 5，安装环境支持 \033[0m"        &&yum install -y ${SoftMake}
echo -e "\n\033[1m \033[44;35m 6，创建nginx用户www \033[0m"   &&useradd -s /sbin/nologin -r www

# 2.1 选择nginx版本并下载
NginxVersion_List
read -p " 请复制您需要编译安装的版本选择安装：" NginxVersion
echo -e "\n\033[1m \033[44;35m 7，下载nginx...... \033[0m"   &&wget http://nginx.org/download/${NginxVersion}.tar.gz

# 2.2 编译安装nginx
tar -xf ${NginxVersion}.tar.gz && cd ${NginxVersion} 
echo -e "\n\033[1m \033[44;35m 8，预编译...... \033[0m"          && ./configure ${ConfigureMoudule}
echo -e "\n\033[1m \033[44;35m 9，编译安装 \033[0m"              && make &&make install

# 2.3 关闭SeLinux
setenforce 0 &&Off_Selinux

# 2.4 防火墙开放端口
firewall-cmd --zone=public ${Firewalld_Open_port} --permanent &&firewall-cmd --reload

# 2.5 查看防火墙开放的端口
List_Open_port

# 2.6 运行nginx 并查看状态
/usr/local/nginx/sbin/nginx
echo -e "\n nginx运行状态：" &&ps -ef |grep nginx 
echo -e "\n nginx监听状态：" &&netstat -atnlp|grep nginx