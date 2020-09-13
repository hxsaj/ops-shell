#!/usr/bin/env bash
###################################################################
# Function :CentOS7.X 自动安装cobbler服务器，并实现cobbler-web管理    #
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

# [ ---- cobbler ---- 修改客户端部署的操作系统管理员的密码
modification_default_pw(){
	# 指定客户端服务器安装后的默认密码
	read -p "设定 客户端操作系统安装后管理员(linux为：root，windows为：administrator)的默认密码：" CoPw
	# 查找到密码所在行
	CN0=$(awk '/^default_password_crypted/ {print FNR}' /etc/cobbler/settings)
	# 注销密码行
	sed -i "s/^default_password_crypted/#default_password_crypted/g" /etc/cobbler/settings
	# 新增密码行
	sed -i "$(awk '/^#default_password_crypted/ {print FNR}' /etc/cobbler/settings)i default_password_crypted: \"${CoPw}\"" /etc/cobbler/settings
}

# [ ---- cobbler ---- 获取配置中户端操作系统安装后默认管理员（root or administrator）的密码
client_default_pw(){
	Default_PW=$(egrep -E "^default_password_crypted" /etc/cobbler/settings|awk -F "\"" '{print$2}')
	echo -e "客户端操作系统安装后默认管理员（root or administrator）密码为：${Default_PW}  "
}



#  程序部署列表 Application deployment list
########## ########## ########## ########## ########## ########## #

# [ ---- cobbler ---- 服务器部署
cobbler_install_program(){
	# 0，内部变量定义
	#  需要部署的软件列表
	#  rsync 同步软件
	#  httpd http服务器
	#  dhcp DHCP服务器
	#  cobbler cobbler服务器
	#  cobbler-web cobbler的web端
	#  tftp tftp-server tftp客户端和服务端
	#  python-ctypes 
	#  xinetd 
	#  pykickstart 
	#  syslinux 
	#  debmirror deb镜像服务（可不装）
	#  fence-agents 电源管理（可不装）
	install_cobbler_list=(rsync httpd dhcp cobbler cobbler-web tftp tftp-server python-ctypes xinetd pykickstart syslinux debmirror fence-agents)
	#  需要多次重启的服务
	server_enable_list=(httpd cobblerd rsyncd xinetd)

	# 1，检查是否是centos7系统
	os_check
	# 2，检查系统SELINUX是否开启，如开启，则关闭
	selinux_check_off
	# 3，检查防火墙状态，如开启，先关闭
	firewalld_check_off
	# 4，检查是否安装epel源，如没有，则自动安装
	soft_check_install epel-release
	# 5，安装cobbler及相关服务
	yum -y install ${install_cobbler_list[@]} && echo -e "${CS} 已完成基础服务安装！${CE}"
	#   注意：注释掉这两行，重新check后没有debmirror相关的报错了（安装debian相关）
	sed -i 's/@dists="sid"/#@dists="sid"/g' /etc/debmirror.conf
	sed -i 's/@arches="i386"/#@arches="i386"/g' /etc/debmirror.conf
	#  启动服务
	server_enable_list=(httpd cobblerd rsyncd xinetd)
	systemctl restart ${server_enable_list[@]}
	systemctl enable ${server_enable_list[@]} dhcpd
	# 6，配置cobbler服务
	# 备份配置文件
	backup_file /etc/cobbler/settings
	#  获取可设定为 cobbler 服务器的 IP（需要修改为PXE客户端能访问到的ip，默认的127.0.0.1仅本机能访问）
	get_host_ip && read -p "检测到本机有上述 IP，请设置其一为cobbler服务器的IP(输入完整 IP) ：" CoSerIP
	#  执行设定 cobbler 服务器IP
	sed -i "s/server: 127.0.0.1/server: ${CoSerIP}/g" /etc/cobbler/settings
	#  执行设定 next_server 服务器IP（同 cobbler IP）
	sed -i "s/next_server: 127.0.0.1/next_server: ${CoSerIP}/g" /etc/cobbler/settings
	#  开启 DHCP 管理
	sed -i 's/manage_dhcp: 0/manage_dhcp: 1/g' /etc/cobbler/settings
	#  限定 PXE 服务
	sed -i 's/pxe_just_once: 0/pxe_just_once: 1/g' /etc/cobbler/settings
	#  获取默认的 cobbler  客户端操作系统安装后的管理员密码
	client_default_pw
	#  确定是否修改
	read -p "是否需要定制（y / n） ？：" Ch_Default_PW
	#  确定即修改默认密码
	[[ ${Ch_Default_PW} = "y" -o ${Ch_Default_PW} = "Y" ]] && modification_default_pw
	# 7，配置 tftp 服务
    #  备份配置文件
    backup_file /etc/xinetd.d/tftp
    #  开启 TFTP 服务
    tftp_open
    # 8，配置 cobbler 的 DHCP 文件（配置文件的网段必须是可联通的网段）/etc/cobbler/dhcp.template

	subnet 10.0.0.0 netmask 255.255.255.0 {
       option routers             10.0.0.2;
       option domain-name-servers 10.0.0.2;
       option subnet-mask         255.255.255.0;
       range dynamic-bootp        10.0.0.100 10.0.0.200;


    #  下载cobbler系统TFTP目录中的所需文件
    cobbler get-loaders
    #  同步更改后的信息，需要多次进行
    cobbler sync
    # 9，重启服务
    systemctl restart ${server_enable_list[@]}
    # 10，开启 cobbler_web 服务
    #  生成账户和密码
    read -p "设定 cobbler 账号的web登录密码：" Cobller_PW
    htdigest /etc/cobbler/users.digest "Cobbler" cobbler

    # 网页登录
    echo -e "cobbler服务部署完成！

    1，iso镜像导入方式如下：
       mount /dev/cdrom /mnt/
       cobbler import --path=/mnt --name=rhel-7 --arch=x86_64
       //说明：
         --path      //镜像路径
         --name      //为安装源定义一个名字
         --arch      //指定安装源平台

       //安装源的唯一标示就是根据name参数来定义，本例导入成功后，安装源的唯一标示就是：rhel-7-x86_64，如果重复，系统会提示导入失败
       //查看cobbler镜像列表

       # cobbler list

       参考：https://www.cnblogs.com/liping0826/p/12155291.html


    2，cobbler_web管理
       默认账户：cobbler  默认密码：cobbler： 
       登录地址：https://${CoSerIP}/cobbler_web
       错误日志：/etc/httpd/logs/error_log

       参考鸣谢：https://www.cnblogs.com/91donkey/p/11635400.html
"
}

# cobbler 安装脚本生效
cobbler_install_program