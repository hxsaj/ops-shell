#!/usr/bin/env bash
###################################################################
# Function :CentOS7.X 常用小工具                                    #
# Platform :RedHatEL7.x Based Platform                            #
# Version  :1.0                                                   #
# Date     :2020-09-24                                            #
# Author   :mugoLH                                                #
# Contact  :houxiaoshuai@baidu.com & hxsaj@126.com                #
# Company  :                                                      #
# depend on:                                                      #
###################################################################
#  公共函数列表 List of common functions
########## ########## ########## ########## ########## ########## #

# [ ---- 000 ---- 获取此工具函数列表
function get_tools_list(){
	grep -v "^#" ./int_os_tools.list|
	awk 'BEGIN{
		print "------------------------------------------------------------------------------------------";
		print "|序号|        函数        |         参数个数及参数          |              说明          |";
		print "------------------------------------------------------------------------------------------";
		}
		{
			printf "| %-2s %-20s %-2s %-29s %-24s \n",$1,$2,$3,$4,$5;
		}
		END{
			print "------------------------------------------------------------------------------------------";
		}'
}

# [ ---- 001 ---- 获取本机 IP 地址
function get_host_ip(){
	ip a|grep -w inet|grep -v docker|grep -w global|awk -F "/" '{print $1}'|awk '{print $2}'
}

# [ ---- 002 ---- 获取出口 IP 地址
function get_public_ip(){
	curl http://members.3322.org/dyndns/getip
}

# [ ---- 003 ---- 备份文件
function backup_file(){
	# 获取备份文件目录
	back_dir=$(dirname $1)
	# 获取备份文件（目录）名
	back_name=$(basename $1)
	# 备份文件
	cp $1{,.bak}
	show_notice 生成备份文件：${back_dir}/${back_name}.bak
}

# [ ---- 004 ---- 打包备份文件（目录）
function backup_file_tar(){
	# 获取备份文件目录
	back_dir=$(dirname $1)
	# 获取备份文件（目录）名
	back_name=$(basename $1)
	# 进入目录开始备份，
	cd ${back_dir} && tar -zcf ${back_name}.tar.gz ./${back_name}
	cd - > /dev/null 2>&1
	show_notice 生成备份文件：${back_dir}/${back_name}.tar.gz
}

# [ ---- 005 ---- Selinux检测及关闭 
function check_off_selinux(){
	if [ `getenforce`z != "Disabled"z ];then
		#  关闭 selinux 服务
		if [ `getenforce`z = "Permissive"z ];then show_notice " Selinux 服务检测为 临时关闭状态！ "
		elif [ `getenforce`z = "Enforcing"z ] ;then setenforce 0 && show_notice " Selinux 服务 已临时关闭 "
		fi
		#  永久禁用 selinux 服务
		source /etc/selinux/config
		if [ ! $SELINUX = 'disabled' ];then
		sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config && \
		show_notice " SeLinux 服务 已执行禁用，重启操作系统生效。"
		elif [ $SELINUX = 'disabled' ];then
		show_notice " SeLinux 服务 已禁用 "
		fi
	fi
}

# [ ---- 006 ---- 防火墙检测及关闭
function check_off_firewalld(){
	if [ `systemctl status firewalld.service|grep Active|grep running|wc -l`z = "1"z ];then
		systemctl stop firewalld.service && \
		show_notice " Firewalld 防火墙 关闭 完成 "
		systemctl disable firewalld.service && \
		show_notice " Firewalld 防火墙 禁用 完成 ，如需启用，请执行 systemctl enable firewalld.service "
	else
	    show_notice " Firewalld 防火墙 关闭 完成 "
	fi
}

# [ ---- 007 ---- 检测系统分支
function check_os_version(){
	awk '{print$1"-"$4}' /etc/redhat-release|awk -F "." '{print$1}'
}

# [ ---- 008 ---- 生成密钥函数
function create_ssh-keygen(){
	#  检查是否已有密钥对
	if [ ! -f ~/.ssh/id_rsa.pub ];then
	#  静默生成密钥对
	ssh-keygen -t rsa -b 2048 -N '' -f ~/.ssh/id_rsa -q && \
	show_notice "生成密钥对完成"
	#  已存在密钥对的情况
	elif [ -f ~/.ssh/id_rsa.pub ];then
	show_notice "密钥对已存在，请核查"
	fi
}

# [ ---- 009 ---- 推送密钥函数
function push_ssh-key(){
	#  判断是否存在密钥对
	if  [ -f ~/.ssh/id_rsa.pub -a -f ~/.ssh/id_rsa ];then
	#  推送密钥到目标服务器
	    ssh-copy-id $(whoami)@$1
	else
	    ssh-keygen -t rsa -b 2048 -N '' -f ~/.ssh/id_rsa -q && \
		ssh-copy-id $(whoami)@$1
	fi
}

