# docker project
1. 配置支持redis-session-manager的tomcat8镜像
2. 通过consul-server，实现consul-nginx自动发现tomcat8服务节点信息，并随着tomcat8节点的增减，动态更新nginx的代理文件。
3. 常用docker工具，docker-compose docker-machine
4. wordpress一键启动脚本
5. Glusterfs文件系统，作为docker持久化数据平台，安装及数据存储形式说明
6. docker网络方案
  6.1 weave
  6.2 flannel
7. Docker开源仓库Harbor


# 待补充
1. ceph实现docker数据持久化
2. DOCKER实现gitlab通过git runner同jenkins实现自动化集成
3. Docker部署ELK实现容器日志的管理
4. Docker部署Zabbix，实现对容器的管理


# 常用别名
alias gita='git pull && git add -a && git commit -m "update" && git push -u origin master'
