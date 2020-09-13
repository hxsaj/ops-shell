#!/bin/bash
##获取巡检开始时间
start_time=`date +%s`
nopass_items_name=()
nopass_items_error=()
pass_items_name=()
##threshold_load为系统负载的告警阈值, loadavg阀值应与核数相关联
#threshold_load=32
threshold_load=`cat /proc/cpuinfo| grep "^processor" -c`
##threshold_cpu为cpu使用率的告警阈值
threshold_cpu=80
##threshold_free为内存的告警阈值单位为G
threshold_free=15
##threshold_disk为磁盘容量的告警阈值单位为%
threshold_disk=85
##threshold_util为io等待的告警阈值单位为%
threshold_util=95
##threshold_net为网卡的告警阈值单位为%
threshold_net=80
##获取主机的IP地址
host_ip=`ip a | grep -A1 -E "bond|xgbe|vnic" | grep inet | grep  -v "inet6\|127.0.0.1" |awk -F'[ /]+' '{print$3}'`
##获取主机名
host_name=`hostname`
##获取磁盘使用率
disk_info=`df -h | grep "dev" |awk '{print$1,";"$5,";"$6}' |sed 's/[[:space:]]*//g'`
##获取内存使用率
available_free=`expr $(cat /proc/meminfo  |grep MemAvailable | awk '{print$2}') / 1048576`
##获取cpu使用率
available_cpu=`expr 100 - $(mpstat 1 1 | tail -1 | awk  '{print$11}' | awk -F'.' '{print$1}')`
##获取系统负载
sys_load=`cat /proc/loadavg| awk '{print$3}'`
##获取io使用率
util_info=`iostat -xk | sed -n '7,$p' | grep -v "^$" | awk '{print$1,";"$NF}' | sed 's/[[:space:]]*//g'`
check_server_mem_usage(){
if [ $available_free -lt $threshold_free ];then
   nopass_items_name[${#nopass_items_name[*]}]="check_server_mem_usage"
   #nopass_items_error[${#nopass_items_error[*]}]="$host_name/$host_ip节点可用内存不足$threshold_free"G"当前可用内存为:$available_free"G""
   nopass_items_error[${#nopass_items_error[*]}]="{\\\"$s/$s节点可用内存不足$s“G”当前可用内存为$s"G"\\\": [\\\"$host_name\\\", \\\"$host_ip\\\", \\\"$threshold_free\\\", \\\"$available_free\\\"]}"
else
   pass_items_name[${#pass_items_name[*]}]="check_server_mem_usage"
fi
}
check_server_load_usage(){
if [ `echo $sys_load | awk -F'.' '{print$1}'` -ge $threshold_load ];then
   nopass_items_name[${#nopass_items_name[*]}]="check_server_load_usage"
   #nopass_items_error[${#nopass_items_error[*]}]="$host_name/$host_ip节点系统十五分钟负载已超过阈值$threshold_load当前为$sys_load"
   nopass_items_error[${#nopass_items_error[*]}]="{\\\"%s/%s节点系统十五分钟负载已超过阈值%s当前为%s\\\": [\\\"$host_name\\\", \\\"$host_ip\\\", \\\"$threshold_load\\\", \\\"$threshold_load\\\"]}"
else
   pass_items_name[${#pass_items_name[*]}]="check_server_load_usage" 
fi
}
check_server_cpu_usage(){
    if [ $available_cpu -le $threshold_cpu ];then
       pass_items_name[${#pass_items_name[*]}]="check_server_cpu_usage"
    else
       nopass_items_name[${#nopass_items_name[*]}]="check_server_cpu_usage"
       #nopass_items_error[${#nopass_items_error[*]}]="$host_name/$host_ip节点CPU使用率超过阈值$threshold_cpu%当前cpu使用率$available_cpu%"
       nopass_items_error[${#nopass_items_error[*]}]="{\\\"%s/%s节点CPU使用率已超过阈值%s%当前CPU使用率为%s%\\\": [\\\"$host_name\\\", \\\"$host_ip\\\", \\\"$threshold_cpu\\\", \\\"$available_cpu\\\"]}"
    fi
}
check_server_disk_usage(){
for disk_i in `echo $disk_info`
do
    disk_use=`echo "$disk_i" |egrep -o "([0-9]{1,3})%" | sed 's/%//g'`
    disk_partition=`echo "$disk_i" |awk -F';' '{print$3}'`
    disk_mount=`echo "$disk_i" |awk -F';' '{print$1}'`
    if [ $disk_use -ge $threshold_disk  ];then
       nopass_items_name[${#nopass_items_name[*]}]="check_server_disk_usage"
       #nopass_items_error[${#nopass_items_error[*]}]="$host_name/$host_ip节点$disk_partition磁盘利用率已超过阈值$threshold_disk%挂载点为:$disk_mount当前已使用:$disk_use%"
       nopass_items_error[${#nopass_items_error[*]}]="{\\\"%s/%s节点%s磁盘利用率已超过阈值%s%挂载点为:%s当前已使用%s%\\\": [\\\"$host_name\\\", \\\"$host_ip\\\", \\\"$disk_partition\\\", \\\"$threshold_disk\\\", \\\"$disk_mount\\\", \\\"$disk_use\\\"]}"
    else
       pass_items_name[${#pass_items_name[*]}]="check_server_disk_usage"
    fi
done
}
check_server_io_usage(){
for util_i in `echo $util_info`
do  
     util_use=`echo "$util_i" |egrep -o "([0-9]{1,3})\.([0-9]{1,3})" `
     util_device=`echo "$util_i" |awk -F';' '{print$1}'`
     if [ `echo $util_use|awk -F'.' '{print$1}'` -ge $threshold_util  ];then
        nopass_items_name[${#nopass_items_name[*]}]="check_server_io_usage"
        #nopass_items_error[${#nopass_items_error[*]}]="$host_name/$host_ip节点$util_device磁盘IO利用率已超过阈值$threshold_util%当前已使用:$util_use%"
        nopass_items_error[${#nopass_items_error[*]}]="{\\\"%s/%s节点%s磁盘IO利用率已超过阈值%s%当前已使用:%s%\\\": [\\\"$host_name\\\", \\\"host_ip\\\", \\\"$util_device\\\", \\\"$threshold_util\\\", \\\"$util_use\\\"]}"
     else
        pass_items_name[${#pass_items_name[*]}]="check_server_io_usage"
     fi
done
}
check_server_network_usage(){
net_list=`sar -n DEV 1 1 |grep xgbe | grep ": "|awk '{print$2,";"$5,";"$6}'| sed 's/[[:space:]]*//g' | sort -t ";" -k 1 -u`
for net_i in `echo $net_list`
do
    net_name=`echo $net_i | awk -F';' '{print$1}'`
    net_speed=`ethtool $net_name | grep "Speed" | egrep -o "[0-9]{1,10}"`
    # 部分网卡未使用，略过
    if [[ "$net_speed" == "" ]];then
      continue
    fi
    net_80=`echo "scale=2;100 / $net_speed"|bc`
    receive_size=`echo $net_i |awk -F';' '{print$2}'`
    receive_use=`echo "scale=10;$receive_size / 1024 * $net_80"|bc `
    transmission_use=`echo "scale=10;$(echo $net_i |awk -F';' '{print$3}') / 1024 * $net_80" | bc`
    if [[  `echo $receive_use |awk -F'.' '{print$1}'` = "" ]];then
       pass_items_name[${#pass_items_name[*]}]="check_server_network_usage"
    elif [ `echo $receive_use |awk -F'.' '{print$1}'` -lt $threshold_net ];then
       pass_items_name[${#pass_items_name[*]}]="check_server_network_usage"
    elif [ `echo $receive_use |awk -F'.' '{print$1}'`  -ge $threshold_net ];then
       nopass_items_name[${#nopass_items_name[*]}]="check_server_network_usage"
       #nopass_items_error[${#nopass_items_error[*]}]="$host_name/$host_ip节点$net_name收包带宽利用率已超过阈值$threshold_net%当前已使用$receive_use%"
       nopass_items_error[${#nopass_items_error[*]}]="{\\\"%s/%s节点%s收包带宽利用率已超过阈值%s%当前已使用%s%\\\": [\\\"$host_name\\\", \\\"$host_ip\\\", \\\"$net_name\\\", \\\"$threshold_net\\\", \\\"$receive_use\\\"]}"
    fi
    if [[  `echo $transmission_use |awk -F'.' '{print$1}'` = "" ]];then
       pass_items_name[${#pass_items_name[*]}]="check_server_network_usage"
    elif [ `echo $transmission_use |awk -F'.' '{print$1}'` -lt $threshold_net ];then
       pass_items_name[${#pass_items_name[*]}]="check_server_network_usage"
    elif [ `echo $transmission_use |awk -F'.' '{print$1}'`  -ge $threshold_net ];then
       nopass_items_name[${#nopass_items_name[*]}]="check_server_network_usage"
       #nopass_items_error[${#nopass_items_error[*]}]="$host_name/$host_ip节点$net_name发包带宽利用率已超过阈值$threshold_net%当前已使用$transmission_use%"
       nopass_items_error[${#nopass_items_error[*]}]="{\\\"%s/%s节点%s发包带宽利用率已超过阈值%s%当前已使用%s%\\\": [\\\"$host_name\\\",\\\"$host_ip\\\", \\\"$net_name\\\", \\\"$threshold_net\\\", \\\"$transmission_use\\\"]}"
    fi
done
}
case $1 in
check_server_mem_usage)
 check_server_mem_usage
;;
check_server_load_usage)
 check_server_load_usage
;;
check_server_disk_usage)
 check_server_disk_usage
;;
check_server_io_usage)
 check_server_io_usage
;;
check_server_network_usage)
 check_server_network_usage
;;
check_server_cpu_usage)
 check_server_cpu_usage
;;
*)
 check_server_cpu_usage
 check_server_mem_usage
 check_server_load_usage
 check_server_disk_usage
 check_server_io_usage
 check_server_network_usage
;;
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


