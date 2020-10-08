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

#  导入子函数脚本列表 Import the list of subfunction scripts
########## ########## ########## ########## ########## ########## #

#. ./int_color_information.sh        # 导入 回显信息的颜色配置 函数                show_notice show_warning show_error
#. ./int_selinux_firewalld.sh        # 导入 禁用 selinux 和 firewalld 函数        selinux_check_off irewalld_check_off
#. ./int_back_file_tar.sh            # 导入 备份文件（目录） 函数                  backup_file backup_file_tar
#. ./int_get_ip.sh                   # 导入 获取ip 函数                           get_host_ip get_public_ip
#. ./int_ssh-key.sh                  # 导入 生成、推送密钥 函数                    ssh-keygen_distribution ssh-key_push
#. ./int_check_os_install_rpm        # 导入 检查系统版本和软件安装 函数             os_check soft_check_install 
 


# cd `dirname $0`

#  公共函数列表 List of common functions
########## ########## ########## ########## ########## ########## #





# [ ---- ---- 打开 TFTP 服务
function tftp_open(){
	# 查找到开关所在行
	OpenNU=$(awk '/disable/ {print FNR}' /etc/xinetd.d/tftp)
	# 定位行打开开关
	sed -i "${OpenNU} s/yes/no/g" /etc/xinetd.d/tftp
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








shell程序的锁机制


lockfile=/tmp/mylock
if (set -C;echo $$ >$lockfile) 2>/dev/null; then
# set -C 使已存在的文件不能再被写
# echo 不旦生成了锁文件，而且还将pid放入其中
# 当此lock文件存在时，if返回失败，跳到else
  trap 'rm $lockfile; exit $?' INT TERM EXIT    # trap保证了脚本异常中断时，释放锁文件（删）
  {
    my critical code...    # 此处是正式的脚本代码
    my critical code...
    my critical code...
  }
  rm  $lockfile        # 正式代码运行完了，释放锁文件
  trap - INT TERM EXIT    # 恢复trap的设置（如在脚本最后时，非必要恢复）
  exit 0
else
  # 锁文件生效，会跳到此处
  echo "$lockfile exist, pid $(<$lockfile) is running."    # 打印错误信息
  exit 1
fi




