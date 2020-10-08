#!/usr/bin/env bash
###################################################################
# Function :CentOS7.X 部署docker-ce（docker使用阿里云镜像站）        #
# Platform :RedHatEL7.x Based Platform                            #
# Version  :1.0                                                   #
# Date     :2020-08-28                                            #
# Author   :mugoLH                                                #
# Contact  :houxiaoshuai@baidu.com & hxsaj@126.com                #
# Company  :                                                      #
# depend on:                                                      #
###################################################################
set -e 
#  导入子函数脚本列表 Import the list of subfunction scripts
########## ########## ########## ########## ########## ########## #
. ../int/int_color_information.sh        # 导入 回显信息的颜色配置 函数                show_notice show_warning show_error
#. ./int/int_back_file_tar.sh            # 导入 备份文件（目录） 函数                  backup_file backup_file_tar


#  变量定义列表 List of variable definitions
########## ########## ########## ########## ########## ########## #

#  清空可能导致的冲突软件列表
docker_remove=(
	docker
	docker-client
	docker-client-latest
	docker-common
	docker-latest
	docker-latest-logrotate
	docker-logrotatedocker-selinux
	docker-engine-selinux
	docker-engine
	)

#  依赖包
docker_depend=(
	audit-libs-python
	checkpolicy
	containerd.io
	container-selinux
	libcgroup
	libsemanage-python
	policycoreutils-python
	python-IPy
	setools-libs
	docker-ce-cli
	)


# 软件下载目录
rpm_download_dir=/root/rpm_download_dir

#  函数列表 List of common functions
########## ########## ########## ########## ########## ########## #

docker_deploy_aliyun_rpm(){
    # 卸载旧版本（如果是新机器可以忽略这一步，centos默认不自带docker服务）
    if rpm -qa|grep docker-engine >/dev/null 2>&1 ;then
    	show_notice "卸载旧版本"                         && yum remove docker* -y > /dev/null 2>&1
    fi
	show_notice "安装软件源工具"                          && yum install -y yum-utils wget bash-completion
	show_notice "安装阿里yum源---备份原repo文件"           && gzip /etc/yum.repos.d/*
	show_notice "安装阿里yum源---下载阿里repo文件"         && wget -O /etc/yum.repos.d/Centos-7.repo http://mirrors.aliyun.com/repo/Centos-7.repo

	# 添加Docker软件包源(选用阿里源)
	show_notice "添加Docker软件包源(选用阿里源)"           && yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
}


#   下载安装包 函数
docker_download_with_network(){
	# 部署阿里云源
	docker_deploy_aliyun_rpm

	# 需要下载的相关软件包
	show_notice "开始下载依赖包及docker-ce软件包" 

	if [ ! -d ${rpm_download_dir} ];then
		mkdir -p ${rpm_download_dir}
	fi

	yum install   ${docker_depend[@]} docker-ce --downloadonly --downloaddir=${rpm_download_dir} > /dev/null 2>&1
	yum reinstall ${docker_depend[@]} docker-ce --downloadonly --downloaddir=${rpm_download_dir} > /dev/null 2>&1
	show_notice " Docker-ce依赖软件包下载完成！软件清单如下：" && ls -lh ${rpm_download_dir}

}

#   在线安装 函数
docker_install_with_network(){
	# 有网环境下docker-ce安装（最新版本docker-ce）
	docker_deploy_aliyun_rpm &&yum install -y docker-ce
}

#   离线安装 函数
docker_install_without_network(){
	# 无外网环境下安装
	if [ -d ${rpm_download_dir} ];then
		rpm -ih ${Rpm_Dir}/*  --nodeps > /dev/null 2>&1
	fi

}



#  主程序 Main Program
########## ########## ########## ########## ########## ########## #
echo -e "
+---------------------------------------------------
|   1，下载 docker-de 安装软件
|   2，在线安装docker-ce
|   3，离线安装docker-ce
|
+---------------------------------------------------
"

# 选择服务
read -t 30 -p  "选择需要的服务，按序号即可（非以上数字既退出）：" Choices_Service

# 选择结果
case ${Choices_Service} in

    # 下载 docker-de 安装软件
    "1" ) docker_download_with_network        ;;

    # 在线安装docker-ce
	"2" ) docker_install_with_network         ;;

    # 离线安装docker-ce
	"3" ) docker_install_without_network      ;;

    # 提示并退出
	* ) echo "退出脚本，欢迎再次使用！" &&exit   ;;
esac

