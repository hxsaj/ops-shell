#!/usr/bin/env bash
###################################################################
# Function :CentOS7.X 回显色彩定义                                  #
# Platform :RedHatEL7.x Based Platform                            #
# Version  :1.0                                                   #
# Date     :2020-09-24                                            #
# Author   :mugoLH                                                #
# Contact  :houxiaoshuai@baidu.com & hxsaj@126.com                #
# Company  :                                                      #
# depend on:                                                      #
###################################################################

# [ ---- ---- 色彩函数定义 

#    提示
function show_notice () {
	# echo -e "\033[38;46m 色彩测试-提示 \033[0m"
	echo -e "\033[38;46m $@ \033[0m" >&1
}
#    警告
function show_warning () {
	# echo -e "\033[35;46m 色彩测试-警告 \033[0m"
	echo -e "\033[35;46m $@ \033[0m" >&2
}
#    报错
function show_error () {
	# echo -e "\033[1;31;46m 色彩测试-错误 \033[0m"
	echo -e "\033[1;31;46m $@ \033[0m" >&2
}