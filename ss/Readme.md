```
docker pull oddrationale/docker-shadowsocks

docker run -d -p 54285:54285 oddrationale/docker-shadowsocks -s 0.0.0.0 -p 54285 -k yourpasswd -m aes-256-cfb
```

其中，

-d——容器启动后会进入后台
-p（第一个）——指定要映射的端口，使用的格式是hostPort:containerPort，即本地的 54285 端口映射到容器的 54285 端口
-s——服务器IP
-p（第二个）——代理端口
yourpasswd——你的密码
-m——加密方式
