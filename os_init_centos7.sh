#!/usr/bin/env bash
#########################################################
# Function :init system                                 #
# Platform :RedHatEL7.x Based Platform                  #
# Version  :1.0                                         #
# Date     :2020-08-28                                  #
# Author   :mugoLH                                      #
# Contact  :hxsaj@126.com                               #
# Company  :                                            #
#########################################################

Aliyun_Yum_Install(){
	# 1、安装wget
	yum install -y wget

	# 2、下载CentOS 7的repo文件
	wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
	#或者
	#curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
	#3、更新镜像源
	yum clean all && yum makecache
}
