#!/usr/bin/env bash
#CentOS7.X 自动安装cobbler服务器，并实现cobbler-web管理
#

# 1，检查是否是centos7系统
if [ `awk '{print$1"-"$4}' /etc/redhat-release|awk -f "." '{print$1}'`z = "CentOS-7"z ];then
	echo -e "\033[31m\033[1m 您的系统不符合部署要求，请使用CentOS7.x/Redhat7.x安装部署！\033[0m"
	exit
fi

# 2，检查系统SELINUX是否开启，如开启，则关闭
if [ `getenforce`z = "Disabled"z ];then
	echo -e "\033[33m\033[1m SeLinux满足要求 \033[0m"
	
	else 
	# 临时关闭Selinux
	setenforce 0 && echo -e "\033[31m\033[1m 将永久关闭SeLinux服务，如果您有需要，请按需设置SeLinux服务以满足需求（建议关闭）\033[0m"
fi

# 3，检查防火墙状态，如开启，先关闭
if [ `systemctl status firewalld.service|grep Active|grep running|wc -l`z = "1"z ];then
	systemctl stop firewalld.service && echo -e "\033[31m\033[1m 防火墙已关闭 \033[0m"
fi

# 4，检查是否安装epel源，如没有，则自动安装
if [ `rpm -qa |grep epel|wc -l`z = "1"z ];then
	echo -e "\033[1m\033[31m 您的系统已安装epel源 \033[0m"
	else
	echo -e "\033[1m\033[31m 将为您的系统安装epel源 \033[0m"
	yum -y install epel-release
fi

# 5，安装cobbler及相关服务
yum -y install cobbler cobbler-web dhcp tftp-server pykickstart httpd && echo -e "\033[1m\033[31m 已完成基础服务安装！\033[0m"

# 6，配置cobbler服务
	#修改默认的cobbler服务器IP（需要修改为PXE客户端能访问到的ip，默认是127.0.0.1仅仅是本机能访问）
	echo -e "\033[1m\033[31m 本机有如下IP，请输入您需要作为cobbler服务器的IP（tips:设置的ip需要满足PXE客户端能访问到，也是dhcp的服务地址）\033[0m" && hostname -i
	read -p "请输入IP：" CoSerIP
	sed -i "s/server: 127.0.0.1/server: ${CoSerIP}/g" /etc/cobbler/settings
	sed -i "s/next_server: 127.0.0.1/next_server: ${CoSerIP}/g" /etc/cobbler/settings
	sed -i 's/manage_dhcp: 0/manage_dhcp: 1/g' /etc/cobbler/settings
	sed -i 's/pxe_just_once: 0/pxe_just_once: 1/g' /etc/cobbler/settings
	