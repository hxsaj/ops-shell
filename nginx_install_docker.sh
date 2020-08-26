#!/usr/bin/env bash
#############################
# 内容：Centos7 Docker 安装nginx-1.19.2
# 时间：2020年8月21日 23:03:11
# 作者：mugo老侯
############################

#name: nginx install
#path:
#update:202-08-26
set -e

# 1.1.1 获取目前nginx所有版本
function NginxVersion_List() {
	curl http://nginx.org/en/download.html|grep -e "tar.gz\""|awk 'BEGIN{i=1}{gsub("href","\n",$0);i++;print}'|grep tar.gz|grep -v asc|awk -F ">|<" '{print$2}'
}
# 1.1.2 显示所有可通过防火墙的端口
function List_Open_port() {
	firewall-cmd --zone=public --list-ports
}



# 拉取最新nginx版本docker
docker pull nginx 

# 获取最新版本的版本号
Nginx_Version=$(docker inspect --format '{{ index (index .Config.Env) 1 }}' nginx |awk -F "=" '{print$2}')

# 给nginx镜像打标签
docker tag nginx nginx:${Nginx_Version}

# 删除latest标签
docker rmi nginx:latest > /dev/null 2>&1

# 配置文件存放位置设定
read -p "nginx的 配置文件 存放目录(请设定一个新目录，例如：/app/nginx/conf)：" Nginx_Conf_Dir &&mkdir -p ${Nginx_Conf_Dir}
read -p "nginx的 网站文件 存放目录(请设定一个新目录，例如：/app/nginx/html)：" Nginx_Html_Dir &&mkdir -p ${Nginx_Html_Dir}
read -p "nginx的 日志文件 存放目录(请设定一个新目录，例如：/app/nginx/logs)：" Nginx_Logs_Dir &&mkdir -p ${Nginx_Logs_Dir}

# 临时运行nginx
docker run -p 80:80 --name nginx -d nginx:${Nginx_Version} 

# 从容器中取出原始配置文件
docker cp nginx:/etc/nginx ${Nginx_Conf_Dir} &&mv ${Nginx_Conf_Dir}/nginx/* ${Nginx_Conf_Dir}

# 关闭临时容器，并删除容器
docker stop nginx &&docker rm nginx

# 正式启动nginx容器
docker run -p 80:80 --name nginx \
-v ${Nginx_Conf_Dir}:/etc/nginx \
-v ${Nginx_Logs_Dir}:/var/log/nginx \
-v  ${Nginx_Html_Dir}:/usr/share/nginx/html \
-d nginx:${Nginx_Version}

# 打印容器运行状态
docker ps -a

# 打印部署消息
echo -e "
nginx配置文件存放路径：${Nginx_Conf_Dir} 
nginx网站文件存放路径：${Nginx_Html_Dir}
nginx日志文件存放路径：${Nginx_Logs_Dir}

注意：修改 nginx配置 需要重启容器（命令：docker restart 容器名）
"