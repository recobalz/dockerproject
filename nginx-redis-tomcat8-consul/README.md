1. 启动consulserver镜像
```
root@d1:/# docker run -d --hostname consulserver --name consulserver -p 8500:8500 gliderlabs/consul-server -data-dir /tmp/consul -bootstrap -client 0.0.0.0

通过url可以访问 http://consul:8500

```
2. 启动registrator，监听本地docker的sock文件，并将信息提交跟consulserver
```
root@d1:/# docker run -d --hostname registrator --name registrator --link consulserver:consul -v /var/run/docker.sock:/tmp/docker.sock gliderlabs/registrator:master -internal consul://consul:8500
```
3. 通过consulserver查看监听信息
```
root@d1:/# curl localhost:8500/v1/catalog/services
{"consul":[],"consul-server-8300":[],"consul-server-8301":["udp"],"consul-server-8302":["udp"],"consul-server-8400":[],"consul-server-8500":[],"consul-server-8600":["udp"]}

root@d1:/# curl localhost:8500/v1/catalog/nodes
[{"Node":"consulserver","Address":"172.17.0.2","TaggedAddresses":{"wan":"172.17.0.2"},"CreateIndex":3,"ModifyIndex":25}]
```
4. 启动一个测试用的web服务
```
root@d1:/# docker run -d -e SERVICE_NAME=web -e SERVICE_TAGS=backend tomcat:8.0


root@d1:/# curl localhost:8500/v1/catalog/service/web
[{"Node":"consulserver","Address":"172.17.0.2","ServiceID":"registrator:serene_stonebraker:8080","ServiceName":"web","ServiceTags":["backend"],"ServiceAddress":"172.17.0.7","ServicePort":8080,"ServiceEnableTagOverride":false,"CreateIndex":100,"ModifyIndex":100},{"Node":"consulserver","Address":"172.17.0.2","ServiceID":"registrator:unruffled_dubinsky:80","ServiceName":"web","ServiceTags":["backend"],"ServiceAddress":"172.17.0.4","ServicePort":80,"ServiceEnableTagOverride":false,"CreateIndex":56,"ModifyIndex":56}]

```
5. 启动nginx-consul-template服务
```
root@d1:/# docker run -d --name lb --link consulserver:consul -p 80:80 yeasy/nginx-consul-template

此镜像包含了正常的nginx服务并追加了consul-template，查看其运行脚本
            "Cmd": [
                "/usr/bin/runsvdir",
                "/etc/service"
                
root@lb:/etc/service# ls -R /etc/service
/etc/service:
consul-template  nginx

/etc/service/consul-template:
run  supervise

/etc/service/consul-template/supervise:
control  lock  ok  pid	stat  status

/etc/service/nginx:
run  supervise

/etc/service/nginx/supervise:
control  lock  ok  pid	stat  status

root@lb:/etc/service/consul-template# cat run 
#!/bin/sh

exec consul-template \
     -consul=consul:8500 \
     -template "/etc/consul-templates/nginx.conf:/etc/nginx/conf.d/app.conf:sv hup nginx"
  
root@lb:/etc/service/nginx# cat run 
#!/bin/sh

/usr/sbin/nginx -c /etc/nginx/nginx.conf -t && \
exec /usr/sbin/nginx -c /etc/nginx/nginx.conf -g "daemon off;"   

查看consule-template的配置文件
root@lb:/etc/nginx/conf.d# cat /etc/consul-templates/nginx.conf 
upstream app {
  least_conn;
  {{range service "backend.web"}}server {{.Address}}:{{.Port}} max_fails=3 fail_timeout=60 weight=1;
  {{else}}server 127.0.0.1:65535; # force a 502{{end}}
}

server {
  listen 80 default_server;

  location / {
    proxy_pass http://app;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
  }
}

consule-template会从consulserver处，匹配SERVICE_NAME=web且SERVIER_TAGS=backend的信息，写入到app.conf里，因此要匹配此脚本，必须保证负载容器的SERVICE_NAME和SERVICE_TAGS分别是web和backend

```
6. 增加web服务的数量,查看nginx服务实时更新
```
在未追加服务前，查看nginx的proxy情况
root@d1:~# docker exec -ti lb cat /etc/nginx/conf.d/app.conf
upstream app {
  least_conn;
  server 172.17.0.9:8080 max_fails=3 fail_timeout=60 weight=1;
  server 172.17.0.7:8080 max_fails=3 fail_timeout=60 weight=1;
}

启动两个服务，必须保证SERVICE_NAME=web且SERVIER_TAGS=backend
root@d1:/# docker run -d -e SERVICE_8080_NAME=http_8080 -e SERVICE_NAME=web -e SERVICE_TAGS=backend tomcat:8.0
root@d1:/# docker run -d -e SERVICE_8080_NAME=http_8080 -e SERVICE_NAME=web -e SERVICE_TAGS=backend yeasy/simple-web

查看nginx的proxy情况
root@d1:~# docker exec -ti lb cat /etc/nginx/conf.d/app.conf
upstream app {
  least_conn;
  server 172.17.0.9:8080 max_fails=3 fail_timeout=60 weight=1;
  server 172.17.0.7:8080 max_fails=3 fail_timeout=60 weight=1;
  server 172.17.0.6:8080 max_fails=3 fail_timeout=60 weight=1;
  server 172.17.0.4:80 max_fails=3 fail_timeout=60 weight=1;
}
可以看到proxy已经更新，即便是不同服务不同端口，也可以实现nginx的后端自动负载；同样的道理，如果停掉某个服务，nginx也可以自动摘掉不存在的主机。
root@d1:~# docker rm 2299 -f
2299
root@d1:~# docker exec -ti 8ef cat /etc/nginx/conf.d/app.conf
upstream app {
  least_conn;
  server 172.17.0.9:8080 max_fails=3 fail_timeout=60 weight=1;
  server 172.17.0.7:8080 max_fails=3 fail_timeout=60 weight=1;
  server 172.17.0.4:80 max_fails=3 fail_timeout=60 weight=1;
  
}

server {
  listen 80 default_server;

  location / {
    proxy_pass http://app;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
  }
}
```
7. docker-compose实现，[出处](https://github.com/yeasy/docker-compose-files/tree/master/consul-discovery)
```
# This compose file will boot a typical scalable lb-backend  topology.
# Registrator will listen on local docker socks to maintain all published containers. The information will be written to consulserver
# consul-template will listen on consulserver and update local lb configuration.
# http://yeasy.github.com


#backend web application, scale this with docker-compose scale web=3
web:
  image: yeasy/simple-web:latest
  environment:
    SERVICE_NAME: web
    SERVICE_TAGS: backend
  ports:
  - "80"

#load balancer will automatically update the config using consul-template
lb:
  image: yeasy/nginx-consul-template:latest
  hostname: lb
  links:
  - consulserver:consul
  ports:
  - "80:80"

consulserver:
  image: gliderlabs/consul-server:latest
  hostname: consulserver
  ports:
  - "8300"
  - "8400"
  - "8500:8500"
  - "53"
  command: -data-dir /tmp/consul -bootstrap -client 0.0.0.0

# listen on local docker sock to register the container with public ports to the consul service
registrator:
  image: gliderlabs/registrator:master
  hostname: registrator
  links:
  - consulserver:consul
  volumes:
  - "/var/run/docker.sock:/tmp/docker.sock"
  command: -internal consul://consul:8500
  #command: consul://consul:8500
```
根据自己的实际情况，修改后的配置文件
```
redis:
  image: redis

web:
  image: tm8
  environment:
    SERVICE_NAME: web
    SERVICE_TAGS: backend
  volumes:
  - "/code/1:/code"
  links:
  - redis:redis

lb:
  image: yeasy/nginx-consul-template:latest
  hostname: lb
  links:
  - consulserver:consul
  ports:
  - "80:80"

consulserver:
  image: gliderlabs/consul-server:latest
  hostname: consulserver
  ports:
  - "8300"
  - "8400"
  - "8500:8500"
  - "53"
  command: -data-dir /tmp/consul -bootstrap -client 0.0.0.0

registrator:
  image: gliderlabs/registrator:master
  hostname: registrator
  links:
  - consulserver:consul
  volumes:
  - "/var/run/docker.sock:/tmp/docker.sock"
  command: -internal consul://consul:8500
  #command: consul://consul:8500  
  
```

8. docker swarm docker-compose实现
```
......
```
