#!/usr/bin/env bash
# 进入需要共享的目录，设定共享的端口，使用Python开启http服务

echo -e "\n欢迎使用Python简单HTTP服务！\n"
read -t 30 -p "请输入需要服务的目录： " SDir
read -t 30 -p "请输入共享端口：" Sdn
cd ${SDir} &&python -m SimpleHTTPServer ${Sdn}
