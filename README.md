## 进程监控
通过 etc/conf/pmonitor_conf.lua 读取要监控的进程
并调用程序自带的 启动脚本 启动 

## install 
### 安装skynet
1. 拉取skyent 
git clone https://github.com/cloudwu/skynet.git
2. 编译 skynet 
$ cd skynet 
$ make linux 
3. 将skynet路径添加到环境变量 
$ echo "export SKYNET=$(pwd)" >> ~/.bash_profile
$ source ~/.bash_profile

### 运行
1. 拉取pmonitor
git clone https://github.com/Shineflag/pmonitor.git

2.按照自己的需求 修改配置
etc/conf/pmonitor_conf.lua
gdir 表示 启动脚本的路径
(要报警的话 手动复制 etc/conf/notify_conf)

3.运行 
./start.sh -d


## 注
当有本进程有监听端口时, 
即使进程关闭时,所占用端口也不释放(当有监控所重启的进程存在时)
当本进程有重启监控进程时， etc/skynet.pid会被lock
在./start.sh -k的时候把它删除，不然下次启动会不成功


