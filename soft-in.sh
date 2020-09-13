#!/usr/bin/env bash
###################################################################
# Function :CentOS7.X 服务安装目录及自制公共函数库                    #
# Platform :RedHatEL7.x Based Platform                            #
# Version  :1.0                                                   #
# Date     :2020-08-28                                            #
# Author   :mugoLH                                                #
# Contact  :houxiaoshuai@baidu.com & hxsaj@126.com                #
# Company  :                                                      #
# depend on:                                                      #
###################################################################

#  公共变量列表 List of common variables
########## ########## ########## ########## ########## ########## #

# [ ---- ---- 色彩函数定义
#  测试语句：
#  Cs   echo -e "\033[31m\033[1m hi baidu \033[0m" 
#  Cs0  echo -e "\033[30;46m hi baidu \033[0m" 
#  Cs1  echo -e "\033[31m hi baidu \033[0m" 

#    提示
function show_notice () {
	# echo -e "\033[34;46m 色彩测试-提示 \033[0m"
	echo -e "\033[34;46m $@ \033[0m" >&1
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
# cd `dirname $0`

#  公共函数列表 List of common functions
########## ########## ########## ########## ########## ########## #

# [ ---- ---- 备份文件
function backup_file(){
	cp $1{,.bak}
}

# [ ---- ---- 软件检测安装 
function soft_check_install(){
	if [ `rpm -qa |grep "$1"|wc -l` -eq 0 ];then
		show_warning " 系统未安装 $1 ,将执行安装 "
		yum -y install $1
	fi
}

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

# [ ---- ---- 检测系统分支
function os_check(){
	if [ `awk '{print$1"-"$4}' /etc/redhat-release|awk -F "." '{print$1}'`z != "CentOS-7"z ];then
		show_warning " 您的系统不符合部署要求，请使用CentOS7.x/Redhat7.x安装部署！"
		exit 1
	fi
}

# [ ---- ---- 防火墙检测及关闭
function firewalld_check_off(){
	if [ `systemctl status firewalld.service|grep Active|grep running|wc -l`z = "1"z ];then
		systemctl stop firewalld.service && show_warning " Firewalld 防火墙未关闭，已关闭 "
	fi
}

# [ ---- ---- 获取本机 IP 地址
function get_host_ip(){
	ip a|grep -w inet|grep -w global|awk -F "/" '{print $1}'|awk '{print $2}'
}

# [ ---- ---- 打开 TFTP 服务
function tftp_open(){
	# 查找到开关所在行
	OpenNU=$(awk '/disable/ {print FNR}' /etc/xinetd.d/tftp)
	# 定位行打开开关
	sed -i "${OpenNU} s/yes/no/g" /etc/xinetd.d/tftp
}

# [ ---- ---- 生成密钥函数
function ssh-keygen_distribution(){
	#  静默生成密钥对
	ssh-keygen -t rsa -b 2048 -N '' -f /root/.ssh/id_rsa -q &&echo -e "生成密钥对完成"
}

# [ ---- ---- 推送密钥函数
function shh-key_push(){
	#  循环推送密钥到目标服务器
	if  [[ -f /root/.ssh/id_rsa.gz ]] ;then
		IPr=""
		until [[ ${IPr} = "q" || ${IPr} = "Q" ]];do
		  echo -ne "请输入目标服务器IP（退出输入q/Q）："
	 	  read IPr && ssh-copy-id root@${IPr}
	    done
	else
		echo -e "密钥不存在，是否生成密钥对？（y/n）：\n"
		read key_to
		if [[ ${key_to} = "y" || ${key_to} = "Y" ]];then
			ssh-keygen -t rsa -b 2048 -N '' -f /root/.ssh/id_rsa -q &&echo -e "生成密钥对完成"
		else
			exit 1
		fi
	fi	
}


#  软件服务目录 Service catalog
########## ########## ########## ########## ########## ########## #
echo -e "
  1，Cobbler 服务部署
  2，NFS     服务部署
  3，yum     服务部署(实时公网同步)
  4，Nginx	 服务部署
  5，pyHttp  服务启动(python简单http服务含upload功能)
  6，Zabbix  服务部署

  q，退出选择

"
read -t 60 -p "输入序号，现在服务：" Select_service
case in ${Select_service}
	"1" ) source ./soft-in-cobbler.sh                   ;;
	"2" ) source ./soft-in-nfs.sh                       ;;

	"q" ) echo -e "欢迎再次使用服务目录 from BD" && exit 0 ;;
    # 输入不规范提示并退出
	* ) echo "输入有误，请重新执行！" &&exit 1             ;;
esac

#  End
########## ########## ########## ########## ########## ########## #