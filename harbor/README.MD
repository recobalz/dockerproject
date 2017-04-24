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

安装过程后下载相关的images，并导入habor.cfg；默认情况下，harbor启动nginx的80端口，如果端口有冲突的话，可以自行修改映射即可。
启动后，打开域名对于的URL即可，（后期补图）



