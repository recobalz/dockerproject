此镜像基于官方tomcat:8.0版本，修改一下信息
1. 加入了tomcat-redis-session-manager相关包
2. 修改server.xml文件，加入了“      <Context crossContext="true" docBase="/code" path="" reloadable="false" />
”，实际docker启动时，需要-v之代码区域
3. 修改了context.xml，指向redis服务器，在实际启动的时候，单机启动的时候，要加入--link参数，docker swarm启动时，要加入hostname
4. 需要配合redis容器启动，否则会有问题

创造镜像
```
cd tm8/
docker build -t tomcat8-redis .
```

启动实例
```
docker run -tid --name redis redis
docker run -v /code:/code --link redis --name tom8 tomcat8-redis

```