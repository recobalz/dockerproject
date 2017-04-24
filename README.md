# docker project
1. 配置支持redis-session-manager的tomcat8镜像
2. 通过consul-server，实现consul-nginx自动发现tomcat8服务节点信息，并随着tomcat8节点的增减，动态更新nginx的代理文件。
