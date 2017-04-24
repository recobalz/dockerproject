两个节点C1和C2，已经在C1和C2上部署了ETCD集群

安装flanet
```
tar xf flannel-v0.7.1-linux-amd64.tar.gz -C /usr/bin
```
已C1为例

启动flannel，指向etcd集群
```
/usr/bin/flanneld -etcd-endpoints=http://c1:2379，http://c2:2379 &
```
执行flannel脚本，生成并导入环境变量文件
```
[root@c1 ~]# mk-docker-opts.sh -i
[root@c1 ~]# source /run/flannel/subnet.env
[root@c1 ~]# cat /run/flannel/subnet.env 
FLANNEL_NETWORK=10.1.0.0/16
FLANNEL_SUBNET=10.1.37.1/24
FLANNEL_MTU=1472
FLANNEL_IPMASQ=false

```

修改docker脚本并重启启动（centos7）
```
[root@c1 ~]# vim /usr/lib/systemd/system/docker.service 
...
ExecStart=/usr/bin/dockerd --bip=10.1.37.1/24   #bip后跟上的是{FLANNEL_SUBNET}
...
[root@c1 ~]# systemctl daemon-reload
[root@c1 ~]# systemctl restart docker.service

```

查看docker网卡信息
```
[root@c1 ~]# ifconfig docker0
docker0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.1.37.1  netmask 255.255.255.0  broadcast 0.0.0.0
        inet6 fe80::42:e8ff:feae:f59  prefixlen 64  scopeid 0x20<link>
        ether 02:42:e8:ae:0f:59  txqueuelen 0  (Ethernet)
        RX packets 682  bytes 54936 (53.6 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 686  bytes 64973 (63.4 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

同样的方式执行C2

检测通讯效果
```
在C1上运行容器
[root@c1 ~]# docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
560d7931dbfa        nginx               "nginx -g 'daemon ..."   11 minutes ago      Up 11 minutes       80/tcp, 443/tcp     lucid_pasteur
e79d217fc633        nginx               "nginx -g 'daemon ..."   11 minutes ago      Up 11 minutes       80/tcp, 443/tcp     stoic_bhabha
[root@c1 ~]# docker exec -ti 560 ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default 
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
71: eth0@if72: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    link/ether 02:42:0a:01:25:04 brd ff:ff:ff:ff:ff:ff
    inet 10.1.37.4/24 scope global eth0
       valid_lft forever preferred_lft forever
[root@c1 ~]# docker exec -ti e79 ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default 
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
69: eth0@if70: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    link/ether 02:42:0a:01:25:03 brd ff:ff:ff:ff:ff:ff
    inet 10.1.37.3/24 scope global eth0
       valid_lft forever preferred_lft forever
```
在C2上运行容器
```
[root@c2 system]# docker exec -ti c40 ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default 
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
12: eth0@if13: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    link/ether 02:42:0a:01:4e:03 brd ff:ff:ff:ff:ff:ff
    inet 10.1.78.3/24 scope global eth0
       valid_lft forever preferred_lft forever
[root@c2 system]# docker exec -ti ccd ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default 
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
10: eth0@if11: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    link/ether 02:42:0a:01:4e:02 brd ff:ff:ff:ff:ff:ff
    inet 10.1.78.2/24 scope global eth0
       valid_lft forever preferred_lft forever
```
       
从C1上测试pingC2的两个容器
```
[root@c1 ~]# docker exec -ti e79 ping -c 2 10.1.78.3 10.1.78.2
PING 10.1.78.3 (10.1.78.3): 56 data bytes
64 bytes from 10.1.78.3: icmp_seq=0 ttl=60 time=2.221 ms
64 bytes from 10.1.78.3: icmp_seq=1 ttl=60 time=0.694 ms
--- 10.1.78.3 ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max/stddev = 0.694/1.458/2.221/0.764 ms
PING 10.1.78.2 (10.1.78.2): 56 data bytes
64 bytes from 10.1.78.2: icmp_seq=0 ttl=60 time=0.560 ms
64 bytes from 10.1.78.2: icmp_seq=1 ttl=60 time=0.405 ms
--- 10.1.78.2 ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max/stddev = 0.405/0.483/0.560/0.078 ms
```
从C2上测试pingC1的两个容器
```
[root@c2 system]# docker exec -ti c40 ping -c 2 10.1.37.3 10.1.37.4
PING 10.1.37.3 (10.1.37.3): 56 data bytes
64 bytes from 10.1.37.3: icmp_seq=0 ttl=60 time=1.055 ms
64 bytes from 10.1.37.3: icmp_seq=1 ttl=60 time=1.146 ms
--- 10.1.37.3 ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max/stddev = 1.055/1.100/1.146/0.046 ms
PING 10.1.37.4 (10.1.37.4): 56 data bytes
64 bytes from 10.1.37.4: icmp_seq=0 ttl=60 time=14.301 ms
64 bytes from 10.1.37.4: icmp_seq=1 ttl=60 time=0.409 ms
--- 10.1.37.4 ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max/stddev = 0.409/7.355/14.301/6.946 ms
```



