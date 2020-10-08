#!/usr/bin/env bash
###################################################################
# Function :CentOS7.X 配置阿里源                                    #
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
. ./int/int_color_information.sh        # 导入 回显信息的颜色配置 函数                show_notice show_warning show_error

function install_yum_aliyun(){
	#  安装 wget 和 自动补全软件包
	yum -y install wget bash-completion
	#  备份yum文件夹所有yum源
	gzip /etc/yum.repos.d/*.repo
	#  利用wget下载阿里云repo文件
	wget -O /etc/yum.repos.d/Centos-7.repo http://mirrors.aliyun.com/repo/Centos-7.repo
	#  执行yum源更新命令
	yum clean all
	#  重建yum元数据
	yum makecache
}
