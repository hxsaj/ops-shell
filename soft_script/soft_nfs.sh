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

#    提示
#function show_notice () {
#	# echo -e "\033[38;46m 色彩测试-提示 \033[0m"
#	echo -e "\033[38;46m $@ \033[0m" >&1
#}
#    警告
#function show_warning () {
#	# echo -e "\033[35;46m 色彩测试-警告 \033[0m"
#	echo -e "\033[35;46m $@ \033[0m" >&2
#}
#    报错
#function show_error () {
#	# echo -e "\033[1;31;46m 色彩测试-错误 \033[0m"
#	echo -e "\033[1;31;46m $@ \033[0m" >&2
#}

#  导入子函数脚本列表 Import the list of subfunction scripts
########## ########## ########## ########## ########## ########## #

# 导入 回显信息的颜色配置 函数
. ../int/int_color_information.sh        # 导入 回显信息的颜色配置 函数                show_notice show_warning show_error

Nfs_Install_Yum(){
	# 准备阶段：测试网络，关闭selinux和防火墙阶段
	show_notice " 1，测试互联网是否畅通（非必须）...... " 
	if ping -c 1 114.114.114.114 >/dev/null 2>&1 ;then
	    show_notice "**********互联网链接正常**********"
	else
		show_warning "**********互联网链接异常**********"
	fi
	
	show_notice " 2，关闭selinux......"
	[[ `getenforce`=="enforcing" ]] && setenforce 0 >/dev/null
	echo -e "**********selinux已关闭**********\n"

	echo -e "${Color_SOD01} 3，关闭防火墙......${Color_EOF01}"
	[[ `systemctl status firewalld|grep Active|awk '{print$2}'`="active" ]] && systemctl stop firewalld >/dev/null 2>&1
	[[ `systemctl status iptables |grep Active|awk '{print$2}'`="active" ]] && systemctl stop iptables  >/dev/null 2>&1
	echo -e "**********防火墙已关闭************\n ${Color_EOF01}"

	# 第二步：确认软件是否安装
	[[ `rpm -aq rpcbind |wc -l` -gt 0 ]] &&echo -e "${Color_SOD01} 4，rpcbind软件已安装${Color_EOF01}" 
	[[ `rpm -aq rpcbind |wc -l` -gt 0 ]] ||(echo -e "4，正在安装rpcbind软件.......\n"&& yum install rpcbind -y >/dev/null  && echo -e "**********rpcbind软件已安装**********\n" )
	[[ `rpm -aq nfs-utils |wc -l` -gt 0 ]] &&echo -e "${Color_SOD01} 5，nfs软件已安装${Color_EOF01}"
	[[ `rpm -aq nfs-utils |wc -l` -gt 0 ]] ||(echo -e "5，正在安装nfs软件......\n" && yum install nfs-utils -y >/dev/null && echo -e "**********nfs软件已安装**********\n" )

	# 第三步：启动服务开机自启动
	systemctl restart rpcbind.service nfs.service
	systemctl enable nfs
	echo -e "${Color_SOD01} nfs共享服务已搭建完成，欢迎使用！${Color_EOF01}"
}

Nfs_Publication_Service(){
	# 如果没有启动，则启动
	systemctl start nfs rpcbind

	# 创建和发布共享目录
	read -p "请输入需要共享的目录：" Exportfs_Dir
	[[ ! -d ${Exportfs_Dir} ]] &&mkdir ${Exportfs_Dir} -p >/dev/null
	chmod 1777 ${Exportfs_Dir}
	read -p "请输入需要共享的网段（如果全网可访问，请输入*）：" Exportfs_Net
	cat >> /etc/exports << END
${Exportfs_Dir}  ${Exportfs_Net}(rw,async,all_squash,insecure,async,wdelay)
END
	exportfs -rv
}

Nfs_Server_off(){
	# 关闭分发，关闭服务
	[[ `showmount -e localhost|grep -v "Export"|wc -l` -gt 0 ]] && echo -e "关闭本服务器全部NFS共享......" && exportfs -u `awk -F "(" '{print$1}' /etc/exports|awk '{print$2":"$1}'`
	[[ `showmount -e localhost|grep -v "Export"|wc -l` -gt 0 ]] || echo -e "本服务器无NFS共享分发......"
}



# 执行选择NFS相关服务
echo -e "${Color_SOD01} \n 欢迎使用NFS部署脚本！
    1，  部署NFS Server
    2，  新增分发共享目录
    off，关闭NFS Server网络文件共享服务
    ${Color_EOF01}"
read -t 60 -p "请选择服务（选择序列号即可）：" Choose_Nfs_Service
case ${Choose_Nfs_Service} in
    # 部署NFS Server
    "1" ) Nfs_Install_Yum                   ;;

    # 新建分发共享目录
    "2" ) Nfs_Publication_Service           ;;

    # NFS Server 关闭分发（不关闭服务进程）
    "off" ) Nfs_Server_off                  ;;

    # 输入不规范提示并退出
	* ) echo "输入有误，请重新执行！" &&exit   ;;
esac
