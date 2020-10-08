#!/usr/bin/env bash
###################################################################
# Function :CentOS7.X 安装 mariadb 数据库                          #
# Platform :RedHatEL7.x Based Platform                            #
# Version  :1.0                                                   #
# Date     :2020-08-28                                            #
# Author   :mugoLH                                                #
# Contact  :houxiaoshuai@baidu.com & hxsaj@126.com                #
# Company  :                                                      #
# depend on:                                                      #
###################################################################

#  导入子函数脚本列表 Import the list of subfunction scripts
########## ########## ########## ########## ########## ########## #
. ../int/int_color_information.sh        # 导入 回显信息的颜色配置 函数                show_notice show_warning show_error
#. ./int/int_back_file_tar.sh            # 导入 备份文件（目录） 函数                  backup_file backup_file_tar
. ../int/int_selinux_firewalld.sh        # 导入 禁用 selinux 和 firewalld 函数       selinux_check_off firewalld_check_off

install_mariadb_yum(){
    #  开始
    show_notice "- star, ---  mariadb 开始安装 ----"
    #  关闭 selinux
    selinux_check_off \
    && show_notice "- 1, ---  关闭 selinux 完成  ----"

    #  关闭 防火墙
    firewalld_check_off \
    && show_notice "- 2, ---  关闭 firewalld 完成  ----"

    #  yum 安装 mariadb
    yum -y install mariadb mariadb-server >/dev/null 2>&1 \
    && show_notice "- 3, ---  安装 mariadb 完成  ----"
    
    #  设置开机启动
    systemctl enable --now mariadb >/dev/null 2>&1 、
    && show_notice "- 4, ---  设置 开机启动mariadb 完成  ----"

    #  初始化 mariadb
    show_notice "- 5, ---  初始化 mariadb  ----"
    mysql_secure_installation

    #  设置服务端字符集
    sed -i "/^\[mysqld\]/a\skip-character-set-client-handshake" /etc/my.cnf
    sed -i "/^\[mysqld\]/a\collation-server=utf8_unicode_ci" /etc/my.cnf
    sed -i "/^\[mysqld\]/a\character-set-server=utf8" /etc/my.cnf
    sed -i "/^\[mysqld\]/a\init_connect=‘SET NAMES utf8’" /etc/my.cnf
    sed -i "/^\[mysqld\]/a\init_connect=‘SET collation_connection = utf8_unicode_ci’" /etc/my.cnf
    show_notice "- 6, ---  mariadb 服务端字符集设置为utf8 完成 ----"

    #  设置客户端字符集
    sed '/^\[mysql\]/a\default-character-set=utf8' /etc/my.cnf.d/mysql-clients.cnf
    sed '/^\[client\]/a\default-character-set=utf8' /etc/my.cnf.d/client.cnf

    show_notice "- 7, ---  mariadb 客户端字符集设置为utf8 完成 ----"
 
    #  安装完成
    show_notice "- done, ---  mariadb 安装结束 ----"

}
