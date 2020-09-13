#!/usr/bin/env bash
###################################################################
# Function :CentOS7.X 自动安装Docker-ce 并替换为阿里镜像源            #
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

# [ ---- docker ---- 安装（阿里源）
Docker-ce_Install_Aliyun(){
	echo "1、docker 所依赖的包环境"          && yum install -y yum-utils device-mapper-persistent-data lvm2
	echo "2、Docker-ce 阿里源镜像"          && yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
	echo "3、更新 yum 软件包"               && yum makecache fast
	echo "4、安装 docke-ce (默认安装最新版)"  && yum -y install docker-ce
	echo "5、启动 docker 并设置开机启动"      && systemctl enable --now docker.service
	echo "6、添加阿里云 docker 镜像加速"      && echo '{ "registry-mirrors": ["https://l3rxe7k8.mirror.aliyuncs.com"] }' > /etc/docker/daemon.json
	echo "7、查看 docker 版本"               && docker version
}

# docker-ce 安装脚本生效
Docker-ce_Install_Aliyun