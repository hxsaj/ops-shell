#!/usr/bin/env bash

# 安装包下载存放位置
Rpm_Dir=/root/work/baidu_docker_rpm

# docker安装包下载（有网环境下的安装包下载）
Docker_Init_Base_Network(){
	# 1.1、卸载旧版本（如果是新机器可以忽略这一步，centos默认不自带docker服务）
	yum remove \
	docker \
	docker-client \
	docker-client-latest \
	docker-common \
	docker-latest \
	docker-latest-logrotate  \
	docker-logrotate \
	docker-selinux \
	docker-engine-selinux \
	docker-engine \
	> /dev/null 2>&1

	# 1.2、安装依赖包
	yum install -y yum-utils device-mapper-persistent-data lvm2

	# 1.3、添加Docker软件包源(选用阿里源)
	yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
}

Docker_Download_Network(){
	# 初始化环境后
	Docker_Init_Base_Network

	# 需要下载的相关软件包
	Soft_For_Docker=(
		yum-utils
		device-mapper-persistent-data
		lvm2
		audit-libs
		audit
		audit-libs-python
		checkpolicy
		libcgroup
		libsemanage-python
		python-IPy
		setools-libs
		policycoreutils-python
		container-selinux
		libtool-ltdl
		containerd.io
		docker-ce
		)

	yum install ${Soft_For_Docker[@]} --downloadonly --downloaddir=${Rpm_Dir} > /dev/null 2>&1
	yum reinstall ${Soft_For_Docker[@]} --downloadonly --downloaddir=${Rpm_Dir} > /dev/null 2>&1
	
	echo -e "\n Docker-ce所需软件下载完成！\n"
}

Docker_Install_with_Network(){
	# 有网环境下docker-ce安装（最新版本docker-ce）
	Docker_Init_Base_Network &&yum install docker-ce
}

Docker_Install_without_Network(){
	# 无外网环境下安装
	Soft_For_Docker=(
		yum-utils
		device-mapper-persistent-data
		lvm2
		audit-libs
		audit
		audit-libs-python
		checkpolicy
		libcgroup
		libsemanage-python
		python-IPy
		setools-libs
		policycoreutils-python
		container-selinux
		libtool-ltdl
		containerd.io
		docker-ce
		)
	#AS=($(for i in  ${Soft_For_Docker[@]}; do ls -lh ${Rpm_Dir}/|grep $i |awk '{print$9}' ; done))
	#rpm -ivh ${AS[@]}
	rpm -ivh ${Rpm_Dir}/$(for i in  ${Soft_For_Docker[@]}; do ls -lh ${Rpm_Dir}/|grep $i |awk '{print$9}' ; done)

}

# ---------------------------------------------------------------#

echo "
1，下载 docker-de 安装软件
2，在线安装docker-ce
3，离线安装docker-ce

"
# 选择服务
read -t 30 -p  "选择需要的服务，按序号即可（都不需要请输入任意非数字字符 ）：" Choices_Service


# 选择结果
case ${Choices_Service} in

    # 下载 docker-de 安装软件
    "1" ) Docker_Download_Network             ;;

    # 在线安装docker-ce
	"2" ) Docker_Install_with_Network         ;;

    # 离线安装docker-ce
	"3" ) Docker_Install_without_Network      ;;

    # 提示并退出
	* ) echo "退出脚本，欢迎再次使用！" &&exit   ;;
esac
