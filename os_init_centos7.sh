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

# 更换阿里云镜像源
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

# 查看路径下文件和目录的大小
Check_Dir_Storage(){
	for FileDir in $1;
	do
		if [ -d "${FileDir}" ]
		then
			echo -e "目录 `du -hs $i`"
		elif [ -f "${FileDir}" ]
		then
			echo -e "文件 `du -hs $i`"
		fi
	done
}

Check_Dir_Storage ./*
