#!/usr/bin/env bash

#echo -e "
#1，140.143.5.204    腾讯云北京云服务器001

#n，上面没有我要的服务器！
#"


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

# [ @函数 ]  输入目标IP
Input_ServerIP(){
	echo ""
	read -t 30 -p "请输入目标服务器IP：" Server_IP
	ssh root@${Server_IP}
}


# ---------------- 打印服务器列表 -------------------------------#
# ---------------------------------------------------------------#

echo "-----------------------------------------------------------"
printf "|%-s\t|%-s\t\t|%-s\n" 序号  IP  服务器
echo "-----------------------------------------------------------"
printf " %-2i\t %-s\t%-s\n" 1 140.143.5.204 腾讯云北京云服务器001

echo ""
printf " %-s\t %-s\t%-s\n" n 上面没有我要的服务器！
echo "-----------------------------------------------------------"

echo ""

# 选择登
read -t 30 -p  "选择需要登录的服务器（如果上面没有您需要的服务器，请输入 n ）：" Choices_Server

# 选择结果
case ${Choices_Server} in

    # 直接登录腾讯服务器
    "1" ) ssh root@140.143.5.204 ;;

    # 用户输入目标服务器ip登录
	  "n" ) Input_ServerIP         ;;

    # 输入不规范提示并退出
	* ) echo "输入有误，请重新执行！" &&exit                   ;;
esac

