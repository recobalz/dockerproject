获取harbor的安装文件,Releases · vmware/harbor  https://github.com/vmware/harbor/releases
```
root@dan:~# wget https://github.com/vmware/harbor/releases/download/v1.1.0/harbor-offline-installer-v1.1.0.tgz
```

解压并查看相关文件
```
root@dan:~# tar xf harbor-online-installer-v1.1.0.tgz 
root@dan:~# ls harbor
common  docker-compose.notary.yml  docker-compose.yml  harbor.cfg  install.sh  LICENSE  NOTICE  prepare
root@dan:~# cat ins
cat: ins: No such file or directory
root@dan:~# cat harbor/install.sh 
#!/bin/bash
......
......
......
```

主要是通过docker-compose文件，启动并加载harbo.cfg文件；修改相关配置
```
root@dan:~# vim harbor/harbor.cfg 
hostname = repo.test.com
harbor_admin_password = 123456

```

完成配置后，install.sh即可
```
root@dan:~# ./install.sh
```

安装过程后下载相关的images，并导入habor.cfg；默认情况下，harbor启动nginx的80端口。

如果需要修改harbor默认80端口，需要修改两个地方
1. 修改docker-compose文件
```
  proxy:
    image: vmware/nginx:1.11.5-patched
    container_name: nginx
    restart: always
    volumes:
      - ./common/config/nginx:/etc/nginx:z
    networks:
      - harbor
    ports:
      - 88:80
      - 443:443
      - 4443:4443
```
2. 修改register的config文件
```
root@reg:/usr/local/harbor# vim common/templates/registry/config.yml 

auth:
  token:
    issuer: harbor-token-issuer
    realm: $ui_url:88/service/token
    rootcertbundle: /etc/registry/root.crt
    service: harbor-registry

```

