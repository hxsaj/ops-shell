#!/usr/bin/env bash

# [ @函数 ]  判断本地是否有密钥
judge_S(){
      if [ ! -f ~/.ssh/id_rsa ];then
       read -p "本地没有密钥，是否生成密钥？(y / n)" CreateS

       # 生成密钥
       if [ ${CreateS}="y" -o ${CreateS}="Y" ];then

           # 执行生成2048位密钥
           ssh-keygen -t rsa -b 2048

           # 生成的密钥推送到目标系统
           if [ -f ~/.ssh/id_rsa ];then
               read -p  "已生成密钥，是否推送到目标服务器？(y / n)" SyncS

               # 询问是否推送
               if [ ${SyncS}="y" -o ${SyncS}="Y" ];then

                   # 推送密钥
                   ssh-copy-id root@${Server_IP}
               fi
           fi
       else
           echo "继续，以输入密码登录！"
       fi
   fi
}


if [ -z $1 ];then
    # ---------------- 打印服务器列表 -------------------------------#
    # ---------------------------------------------------------------#

    echo "-----------------------------------------------------------"
    printf "|%-s\t|%-s\t\t|%-s\n" 序号  IP  服务器
    echo "-----------------------------------------------------------"
    printf " %-2i\t %-s\t%-s\n" 1 140.143.5.204 腾讯云北京云服务器001
    printf " %-2i\t %-s\t%-s\n" 2 47.95.253.175 阿里云老曹云服务器001

    echo "-----------------------------------------------------------"
    echo ""

    # 选择登录
    read -t 30 -p  "选择需要登录的服务器(非选择项的任意键退出)：" Choices_Server
    case ${Choices_Server} in
        # 直接登录腾讯服务器
        "1" ) ssh root@140.143.5.204 ;;
        "2" ) ssh root@47.95.253.175 ;;

        # 用户输入目标服务器ip登录
        #  "n" ) Input_ServerIP         ;;

        # 输入不规范提示并退出
        * ) echo "未选择服务器，已退出" &&exit                   ;;
    esac
else
	ssh root@$1
fi
