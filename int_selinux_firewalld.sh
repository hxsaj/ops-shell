#!/usr/bin/env bash
###################################################################
# Function :CentOS7.X 禁用selinux和关闭firewalld                   #
# Platform :RedHatEL7.x Based Platform                            #
# Version  :1.0                                                   #
# Date     :2020-09-24                                            #
# Author   :mugoLH                                                #
# Contact  :houxiaoshuai@baidu.com & hxsaj@126.com                #
# Company  :                                                      #
# depend on:                                                      #
###################################################################

#  导入子函数脚本列表 Import the list of subfunction scripts
########## ########## ########## ########## ########## ########## #

# 导入 回显信息的颜色配置 函数
# show_notice，show_warning，show_error
. ./int_color_information.sh


# [ ---- ---- Selinux检测及关闭 
function selinux_check_off(){
	if [ `getenforce`z != "Disabled"z ];then
		echo -ne " SeLinux服务未禁用，"
		# 禁止selinux服务
		sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config && show_notice " SeLinux服务已执行禁用，需重启操作系统生效。"
		if [ `getenforce`z = "Permissive"z ];then show_notice " 仅临时关闭，如非必须，建议禁用 "
		elif [ `getenforce`z = "Enforcing"z ] ;then setenforce 0 &&show_notice " 已临时关闭，如非必须，建议禁用 "
		fi
	fi
}

# [ ---- ---- 防火墙检测及关闭
function firewalld_check_off(){
	if [ `systemctl status firewalld.service|grep Active|grep running|wc -l`z = "1"z ];then
		systemctl stop firewalld.service && show_warning " Firewalld 防火墙未关闭，已关闭 "
	fi
}

