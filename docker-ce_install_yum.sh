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
	docker-engine

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
	for i in ${Soft_For_Docker[@]}
	do
		yum install ${i} --downloadonly --downloaddir=${Rpm_Dir}
		yum reinstall ${i} --downloadonly --downloaddir=${Rpm_Dir}
	done
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
	for i in ${Soft_For_Docker[@]}
	do
		rpm -ivh ${Rpm_Dir}/${i}*
	done
}



# 无外网环境下安装
# yum install yum-utils --downloadonly --downloaddir=/root/dockerrpm/
# yum install device-mapper-persistent-data --downloadonly --downloaddir=/root/dockerrpm/
# yum install lvm2 --downloadonly --downloaddir=/root/dockerrpm/
# yum install policycoreutils-python --downloadonly --downloaddir=/root/dockerrpm/
# yum install docker-ce-18.06.1.ce --downloadonly --downloaddir=/root/dockerrpm/

# ypm -ivh audit-libs-2.8.1-3.el7_5.1.x86_64.rpm
# ypm -ivh audit-2.8.1-3.el7_5.1.x86_64.rpm
# ypm -ivh audit-libs-python-2.8.1-3.el7_5.1.x86_64.rpm
# ypm -ivh checkpolicy-2.5-6.el7.x86_64.rpm
# ypm -ivh libcgroup-0.41-15.el7.x86_64.rpm
# ypm -ivh libsemanage-python-2.5-11.el7.x86_64.rpm
# ypm -ivh python-IPy-0.75-6.el7.noarch.rpm
# ypm -ivh setools-libs-3.3.8-2.el7.x86_64.rpm
# ypm -ivh policycoreutils-python-2.5-22.el7.x86_64.rpm
# ypm -ivh container-selinux-2.68-1.el7.noarch.rpm
# ypm -ivh libtool-ltdl-2.4.2-22.el7_3.x86_64.rpm
# ypm -ivh docker-ce-18.06.1.ce-3.el7.x86_64.rpm


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