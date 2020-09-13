#!/bin/bash
##获取巡检开始时间
start_time=`date +%s`
nopass_items_name=()
nopass_items_error=()
pass_items_name=()
##获取主机的IP地址
host_ip=`ip a | grep -A1 -E "bond|xgbe|vnic" | grep inet | grep  -v "inet6\|127.0.0.1" |awk -F'[ /]+' '{print$3}'`
##获取主机名
host_name=`hostname`
##启动ipmi服务
service ipmi start &> /dev/null || systemctl start ipmi &>/dev/null
##获取硬件状态列表
ipmi_sdr_list=`ipmitool sdr list | awk -F'|' '{print$1,";"$3}' | sed  's/[[:space:]]*//g'`
##check_hardware函数通过ipmi来检查硬件是否故障, 支持DISK\NVME\HDD\SATA\HHD\SSD\SCSI
ipmi_disk=`echo $ipmi_sdr_list | sed 's/ /\n/g' | egrep -i  "DISK[0-9]*_Status"||
echo $ipmi_sdr_list | sed 's/ /\n/g' | egrep -i "NVME[0-9]*_status"||
echo $ipmi_sdr_list | sed 's/ /\n/g' | egrep -i "HDD[0-9]*_status"||
echo $ipmi_sdr_list | sed 's/ /\n/g' | egrep -i "HHD[0-9]*_status"||
echo $ipmi_sdr_list | sed 's/ /\n/g' | egrep -i "SSD[0-9]*_status"||
echo $ipmi_sdr_list | sed 's/ /\n/g' | egrep -i "SCSI[0-9]*_status"||
echo $ipmi_sdr_list | sed 's/ /\n/g' | egrep -i "SATA[0-9]*_status"`
ipmi_MotherBoard=`echo $ipmi_sdr_list | sed 's/ /\n/g' | egrep -i MotherBoard`
##sdr中无主板信息，使用主板电源判断
ipmi_chassis_sys_power=`ipmitool -I open chassis status | grep "System Power"| awk '{print$4}'`
ipmi_cpu=`echo $ipmi_sdr_list | sed 's/ /\n/g' | egrep -i "CPU[0-9]*_Status"`
ipmi_sdr_fan=`echo $ipmi_sdr_list | sed 's/ /\n/g' | egrep -i "SYS_Fan[0-9]*_Speed_F"`
##sdr中无风扇信息，使用主板风扇/冷却接口判断
ipmi_chassis_fault_fan=`ipmitool -I open chassis status | grep -i Fan | awk '{print$4}'`
check_ipmi_device_state(){
check_option=$1
device_name=`echo $ipmi_device_info|awk -F';' '{print$1}'`
device_state=`echo $ipmi_device_info|awk -F';' '{print$2}'`
if [ $device_state = ok ];then
    pass_items_name[${#pass_items_name[*]}]="$check_option"
elif [ $device_state = ns ];then
    nopass_items_name[${#nopass_items_name[*]}]="$check_option"
    #nopass_items_error[${#nopass_items_error[*]}]="$host_name/$host_ip节点$device_name设备不在位"
    nopass_items_error[${#nopass_items_error[*]}]="{\\\"%s/%s节点%s设备不在位\\\": [\\\"$host_name\\\", \\\"$host_ip\\\", \\\"$devce_name\\\"]}"
elif [ $device_state = lnc ];then
    nopass_items_name[${#nopass_items_name[*]}]="$check_option"
    #nopass_items_error[${#nopass_items_error[*]}]="$host_name/$host_ip节点$device_name设备存在软件同步问题"
    nopass_items_error[${#nopass_items_error[*]}]="{\\\"%s/%sip节点%s设备存在软件同步问题\\\": [\\\"$host_name\\\", \\\"$host_ip\\\", \\\"$device_name\\\"]}"
elif [ $device_state = lcr ];then
    nopass_items_name[${#nopass_items_name[*]}]="$check_option"
    #nopass_items_error[${#nopass_items_error[*]}]="$host_name/$host_ip节点$device_name设备存在可修复故障需要报修"
    nopass_items_error[${#nopass_items_error[*]}]="{\\\"%s/%s节点%s设备存在可修复故障需要报修\\\": [\\\"$host_name\\\", \\\"$host_ip\\\", \\\"$device_name\\\"]}"
elif [ $device_state = ucr ];then
    nopass_items_name[${#nopass_items_name[*]}]="$check_option"
    #nopass_items_error[${#nopass_items_error[*]}]="$host_name/$host_ip节点$device_name设备存在不可修复故障需要报修"
    nopass_items_error[${#nopass_items_error[*]}]="{\\\"%s/%s节点%s设备存在不修复故障需要报修\\\": [\\\"$host_name\\\", \\\"$host_ip\\\", \\\"$device_name\\\"]}"
elif [ $device_state = cr ];then
    nopass_items_name[${#nopass_items_name[*]}]="$check_option"
    #nopass_items_error[${#nopass_items_error[*]}]="$host_name/$host_ip节点$device_name设备存在故障需要报修"
    nopass_items_error[${#nopass_items_error[*]}]="{\\\"%s/%s节点%s设备存在故障需要报修\\\": [\\\"$host_name\\\", \\\"$host_ip\\\", \\\"$device_name\\\"]}"
else
    nopass_items_name[${#nopass_items_name[*]}]="$check_option"
    #nopass_items_error[${#nopass_items_error[*]}]="$host_name/$host_ip节点$device_name未知问题"
    nopass_items_error[${#nopass_items_error[*]}]="{\\\"%s/%s节点%s未知问题\\\": [\\\"$host_name\\\", \\\"$host_ip\\\", \\\"$device_name\\\"]}"
fi
}
 
check_server_cpu_status(){ 
   for ipmi_device_info in $ipmi_cpu
   do
   check_ipmi_device_state "check_server_cpu_status"
   done
}
check_server_disk_status(){
   for ipmi_device_info in $ipmi_disk
   do
     check_ipmi_device_state "check_server_disk_status"
   done
}
check_server_fan_status(){
   if [[ $ipmi_sdr_fan != '' ]]; then
   for ipmi_device_info in $ipmi_sdr_fan
   do
      check_ipmi_device_state "check_server_fan_status"
   done
   else
      if [[ $ipmi_chassis_fault_fan == 'false' ]]; then
        pass_items_name[${#pass_items_name[*]}]="check_server_fan_status"
      else
        nopass_items_name[${#nopass_items_name[*]}]="check_server_fan_status"
        #nopass_items_error[${#nopass_items_error[*]}]="$host_name/$host_ip节点机架风扇故障，请及时联系机房运维人员"
        nopass_items_error[${#nopass_items_error[*]}]="{\\\"%s/%s节点机架风扇故障，请及时联系机房运维人员\\\": [\\\"$host_name\\\", \\\"$host_ip\\\"]}"
      fi
   fi
}
check_server_mainboard_status(){
   if [[ $ipmi_MotherBoard != '' ]]; then
   for ipmi_device_info in $ipmi_sdr_fan
   do
      check_ipmi_device_state "check_server_mainboard_status"
   done
   else
      if [[ $ipmi_chassis_sys_power == 'on' ]]; then
        pass_items_name[${#pass_items_name[*]}]="check_server_mainboard_status"
      else
        nopass_items_name[${#nopass_items_name[*]}]="check_server_mainboard_status"
        #nopass_items_error[${#nopass_items_error[*]}]="$host_name/$host_ip节点机架主板断电，请及时联系机房运维人员"
        nopass_items_error[${#nopass_items_error[*]}]="{\\\"%s/%s节点机架主板断电，请及时联系机房运维人员\\\": [\\\"$host_name\\\", \\\"$host_ip\\\"]}"
      fi
   fi
}
 
case $1 in
check_server_cpu_status)
 check_server_cpu_status
;;
check_server_disk_status)
 check_server_disk_status
;;
check_server_fan_status)
 check_server_fan_status
;;
check_server_mainboard_status)
 check_server_mainboard_status
;;
*)
 check_server_cpu_status
 check_server_disk_status
 check_server_fan_status
 check_server_mainboard_status
esac
##print_result函数来将结果转换为json格式
function print_result(){
##统计未通过巡检项目的数量
nopass_nums=`echo ${#nopass_items_name[@]}`
##统计通过巡检项目的数量
pass_nums=`echo ${#pass_items_name[@]}`
    if [ `echo ${#nopass_items_name[@]}` -eq 0 ];then
         nopass_items=""
         for item_i in `seq 0 $(expr $pass_nums - 1)`    
         do   
            pass_itemname="${pass_items_name[$item_i]}"
            pass_item="{\"name\": \"$pass_itemname\"}"
            if [ $item_i -eq 0 ];then
               pass_items="${pass_item}"
            else
               pass_items="${pass_items[*]},${pass_item}"
            fi
         done
    else
         for item_i in `seq 0 $(expr $nopass_nums - 1)`
         do
             nopass_itemname="${nopass_items_name[$item_i]}"
             describe="${nopass_items_error[$item_i]}"
             nopass_item="{\"name\": \"$nopass_itemname\",\"description\":\"$describe\"}"
             if [ $item_i -eq 0 ];then
                nopass_items="${nopass_item}"
             else
                nopass_items="${nopass_items[*]},${nopass_item}"
             fi
          done
          for item_i in `seq 0 $(expr $pass_nums - 1)`
          do
             pass_itemname="${pass_items_name[$item_i]}"
             pass_item="{\"name\": \"$pass_itemname\"}"
             if [ $item_i -eq 0 ];then
                 pass_items="${pass_item}"
             else
                 pass_items="${pass_items[*]},${pass_item}"
             fi
          done
 
    fi
##获取巡检结束时间
end_time=`date +%s`
##计算巡检时间
elapsed=`expr $end_time - $start_time`
##输出内容
result="{\"elapsed\":$elapsed,\"result\":[{\"nopass_nums\":$nopass_nums,\"nopass_items\":[$nopass_items],\"pass_nums\":$pass_nums,\"pass_items\":[$pass_items]}]}"
echo $result
exit 0
}
print_result
