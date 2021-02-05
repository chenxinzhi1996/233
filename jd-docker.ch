#!/bin/sh
#
# Copyright (C) 2020 老竭力
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#
clear

echo "
     ██╗██████╗     ██████╗  ██████╗  ██████╗██╗  ██╗███████╗██████╗ 
     ██║██╔══██╗    ██╔══██╗██╔═══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗
     ██║██║  ██║    ██║  ██║██║   ██║██║     █████╔╝ █████╗  ██████╔╝
██   ██║██║  ██║    ██║  ██║██║   ██║██║     ██╔═██╗ ██╔══╝  ██╔══██╗
╚█████╔╝██████╔╝    ██████╔╝╚██████╔╝╚██████╗██║  ██╗███████╗██║  ██║
 ╚════╝ ╚═════╝     ╚═════╝  ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
                                                                     
                     ==== Create by 老竭力 ====                     
              本脚本将会添加作者的助力码，感谢你的支持！             
"
DOCKER_IMG_NAME="evinedeng/jd"
JD_PATH=""
SHELL_FOLDER=$(pwd)
CONTAINER_NAME=""
CONFIG_PATH=""
LOG_PATH=""
GIT_SOURCE="gitee"

HAS_IMAGE=false
PULL_IMAGE=true

HAS_CONTAINER=false
DEL_CONTAINER=true
INSTALL_WATCH=false

TEST_BEAN_CHAGE=false

log() {
    echo -e "\e[32m$1 \e[0m\n"
}

inp() {
    echo -e "\e[33m$1 \e[0m\n"
}

warn() {
    echo -e "\e[31m$1 \e[0m\n"
}

cancelrun() {
    if [ $# -gt 0 ]; then
        echo     "\033[31m $1 \033[0m"
    fi
    exit 1
}

docker_install() {
    echo "检查Docker......"
    if [ -x "$(command -v docker)" ]; then
       echo "检查到Docker已安装!"
    else
       if [ -r /etc/os-release ]; then
            lsb_dist="$(. /etc/os-release && echo "$ID")"
        fi
        if [ $lsb_dist == "openwrt" ]; then
            echo "openwrt 环境请自行安装docker"
            #exit 1
        else
            echo "安装docker环境..."
            curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
            echo "安装docker环境...安装完成!"
            systemctl enable docker
            systemctl start docker
        fi
    fi
}

docker_install
warn "注意如果你什么都不清楚，建议所有选项都直接回车，使用默认选择！！！"
#配置文件目录
echo -n -e "\e[33m一.请输入配置文件保存的绝对路径,直接回车为当前目录:\e[0m"
read jd_path
JD_PATH=$jd_path
if [ -z "$jd_path" ]; then
    JD_PATH=$SHELL_FOLDER
fi
CONFIG_PATH=$JD_PATH/jd_docker/config
LOG_PATH=$JD_PATH/jd_docker/log

#选择镜像
#inp "二.请选择容器中脚本更新源：\n1) gitee[默认]\n2) github"
#echo -n -e "\e[33m输入您的选择->\e[0m"
#read source
#if [ "$source" = "2" ]; then
#    GIT_SOURCE="github"
#fi

#检测镜像是否存在
if [ ! -z "$(docker images -q $DOCKER_IMG_NAME:$GIT_SOURCE 2> /dev/null)" ]; then
    HAS_IMAGE=true
    inp "检测到先前已经存在的镜像，是否拉取最新的镜像：\n1) 是[默认]\n2) 不需要"
    echo -n -e "\e[33m输入您的选择->\e[0m"
    read update
    if [ "$update" = "2" ]; then
        PULL_IMAGE=false
    fi
fi

#检测容器是否存在
check_container_name() {
    if [ ! -z "$(docker ps -a | grep $CONTAINER_NAME 2> /dev/null)" ]; then
        HAS_CONTAINER=true
        inp "检测到先前已经存在的容器，是否删除先前的容器：\n1) 是[默认]\n2) 不要"
        echo -n -e "\e[33m输入您的选择->\e[0m"
        read update
        if [ "$update" = "2" ]; then
            PULL_IMAGE=false
            inp "您选择了不要删除之前的容器，需要重新输入容器名称"
            input_container_name
        fi
    fi
}

#容器名称
input_container_name() {
    echo -n -e "\e[33m三.请输入要创建的Docker容器名称[默认为：jd]->\e[0m"
    read container_name
    if [ -z "$container_name" ]; then
        CONTAINER_NAME="jd"
    else
        CONTAINER_NAME=$container_name
    fi
    check_container_name
}
input_container_name

#是否安装WatchTower
inp "5.是否安装containrrr/watchtower自动更新Docker容器：\n1) 安装\n2) 不安装[默认]"
echo -n -e "\e[33m输入您的选择->\e[0m"
read watchtower
if [ "$watchtower" = "1" ]; then
    INSTALL_WATCH=true
fi


#配置已经创建完成，开始执行

log "1.开始创建配置文件目录"
mkdir -p $CONFIG_PATH
mkdir -p $LOG_PATH


if [ $HAS_IMAGE = true ] && [ $PULL_IMAGE = true ]; then
    log "2.1.开始拉取最新的镜像"
    docker pull $DOCKER_IMG_NAME:$GIT_SOURCE
fi

if [ $HAS_CONTAINER = true ] && [ $DEL_CONTAINER = true ]; then
    log "2.2.删除先前的容器"
    docker stop $CONTAINER_NAME >/dev/null
    docker rm $CONTAINER_NAME >/dev/null
fi

log "3.开始创建容器并执行"
docker run -dit \
    -v $CONFIG_PATH:/jd/config \
    -v $LOG_PATH:/jd/log \
    --name $CONTAINER_NAME \
    --hostname jd \
    --restart always \
    --network host \
    $DOCKER_IMG_NAME:$GIT_SOURCE

if [ $INSTALL_WATCH = true ]; then
    log "3.1.开始创建容器并执行"
    docker run -d \
    --name watchtower \
    -v /var/run/docker.sock:/var/run/docker.sock \
    containrrr/watchtower
fi

#检查config文件是否存在

if [ ! -f "$CONFIG_PATH/config.sh" ]; then
    docker cp $CONTAINER_NAME:/jd/sample/config.sh.sample $CONFIG_PATH/config.sh
    #添加脚本作者助力码
    #sed -i 's/ForOtherFruit1=""/ForOtherFruit1="3bea619de1814b5688e5504af8c58591@c6d6d910e53040a483e7301f518c03c5@e974332dbff343cf864f6e56c2a5224a@6e6e811bf81543e4a57998f98ecc17db"/g' $CONFIG_PATH/config.sh
    #sed -i 's/ForOtherBean1=""/ForOtherBean1="ckvke3ri7sj4c7u3xbhnnuirk4@a355so2hppyl3on7tb3pjq4ose5ac3f4ijdgqji@qpb2rslaqgfqrqgpyys4ntjufi@zbei5cjpebrwm4gkhhsl6qqgg45ac3f4ijdgqji"/g' $CONFIG_PATH/config.sh
    #sed -i 's/ForOtherJdFactory1=""/ForOtherJdFactory1="T0085KgxAldCCjVWnYaS5kRrbA@T0124qggGEtb9FXXCjVWnYaS5kRrbA@T0164qQtFEtBqgqAInWpCjVWnYaS5kRrbA@T0105q8yGkJTrQCjVWnYaS5kRrbA"/g' $CONFIG_PATH/config.sh
    #sed -i 's/ForOtherJdzz1=""/ForOtherJdzz1="S5KgxAldC@S5awtF0VIqwO4c1K9@S4qggGEtb9FXX@S5q8yGkJTrQ"/g' $CONFIG_PATH/config.sh
    #sed -i 's/ForOtherJoy1=""/ForOtherJoy1="mGjQUKjeeEI=@iGRAEiEd8T1nJA1ZYLpP-w==@wntueHBfaacYvhFfcIhoNA==@QPNaobA6Be4="/g' $CONFIG_PATH/config.sh #crazyJoy
    #sed -i 's/ForOtherSgmh1=""/ForOtherSgmh1="T0085KgxAldCCjVWmIaW5kRrbA@T0124qggGEtb9FXXCjVWmIaW5kRrbA@T0164qQtFEtBqgqAInWpCjVWmIaW5kRrbA@QPNaobA6Be4="/g' $CONFIG_PATH/config.sh #闪购盲盒
    #sed -i 's/ForOtherDreamFactory1=""/ForOtherDreamFactory1="D8I4RgldcFCZLoUfMLTLdQ=="/g' $CONFIG_PATH/config.sh #京喜工厂
    #sed -i 's/ForOtherNian1=""/ForOtherNian1="cgxZdTTAZvOBpkKqDX7-p9dG_Vk@cgxZez7cc7nc6wqFRGavrmtZwX9ZH_Lhag@cgxZczTdetWSr1KQWVv-o6F6GFGuKak1fq7cb1WjiS0ZHQ"/g' $CONFIG_PATH/config.sh #炸年兽
    #sed -i 's/ForOtherPet1=""/ForOtherPet1="MTE1NDQ5OTUwMDAwMDAwNDMwNDgyMDE="/g' $CONFIG_PATH/config.sh #东东萌宠
 fi

log "4.下面列出所有容器"
docker ps

log "5.安装已经完成。\n现在你可以访问设备的 ip:5678 用户名：admin  密码：adminadmin  来添加cookie，和其他操作。感谢使用！"
