## 进程监控
通过 etc/conf/pmonitor_conf.lua 读取要监控的进程
并调用程序自带的 启动脚本 启动 


##注
当有本进程有监听端口时, 
即使进程关闭时,所占用端口也不释放(当有监控所重启的进程存在时)
当本进程有重启监控进程时， etc/skynet.pid会被lock
在./start.sh -k的时候把它删除，不然下次启动会不成功


