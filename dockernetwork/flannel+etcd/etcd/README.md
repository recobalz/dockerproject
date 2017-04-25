目前有两个节点，分别是c1和c2


c1的执行脚本
```
etcd \
--name etcd0 \
--data-dir /tmp \
--advertise-client-urls http://c1:2379,http://c1:4001 \
--listen-client-urls http://0.0.0.0:2379,http://0.0.0.0:4001 \
--listen-peer-urls http://0.0.0.0:2380 \
--initial-advertise-peer-urls http://c1:2380 \
--initial-cluster-token etcd-cluster-1 \
--initial-cluster etcd0=http://c1:2380,etcd1=http://c2:2380 \
--initial-cluster-state new > /tmp/etcd.log 2>&1
```

C2的执行脚本
```
etcd \
--name etcd1 \
--data-dir /tmp \
--advertise-client-urls http://c2:2379,http://c2:4001 \
--listen-client-urls http://0.0.0.0:2379,http://0.0.0.0:4001 \
--listen-peer-urls http://0.0.0.0:2380 \
--initial-advertise-peer-urls http://c2:2380 \
--initial-cluster-token etcd-cluster-1 \
--initial-cluster etcd0=http://c1:2380,etcd1=http://c2:2380 \
--initial-cluster-state new > /tmp/etcd.log 2>&1
```

查看集群成员
```
[root@c2 ~]# etcdctl member list
26e7d0561425b2f3: name=etcd1 peerURLs=http://c2:2380 clientURLs=http://c2:2379,http://c2:4001 isLeader=false
89ad16602bcc13e8: name=etcd0 peerURLs=http://c1:2380 clientURLs=http://c1:2379,http://c1:4001 isLeader=true
```

查看集群健康状态
```
[root@c2 ~]# etcdctl cluster-health
member 26e7d0561425b2f3 is healthy: got healthy result from http://c2:2379
member 89ad16602bcc13e8 is healthy: got healthy result from http://c1:2379
cluster is healthy
```

集群读写测试，在C1上写，在C2上读
```
[root@c1 ~]# etcdctl set a 1
1
[root@c2 ~]# etcdctl get a
1
```

REST API
```
[root@c1 ~]# curl http://c1:2379/v2/members 
{"members":[{"id":"26e7d0561425b2f3","name":"etcd1","peerURLs":["http://c2:2380"],"clientURLs":["http://c2:2379","http://c2:4001"]},{"id":"89ad16602bcc13e8","name":"etcd0","peerURLs":["http://c1:2380"],"clientURLs":["http://c1:2379","http://c1:4001"]}]}
[root@c1 ~]# curl http://c2:2379/v2/members 
{"members":[{"id":"26e7d0561425b2f3","name":"etcd1","peerURLs":["http://c2:2380"],"clientURLs":["http://c2:2379","http://c2:4001"]},{"id":"89ad16602bcc13e8","name":"etcd0","peerURLs":["http://c1:2380"],"clientURLs":["http://c1:2379","http://c1:4001"]}]}

[root@c1 ~]# curl -fs -X PUT http://c1:2379/v2/keys/test
{"action":"set","node":{"key":"/test","value":"","modifiedIndex":8,"createdIndex":8}}

[root@c1 ~]# curl -X GET http://c2:2379/v2/keys/test
{"action":"get","node":{"key":"/test","value":"","modifiedIndex":9,"createdIndex":9}}
```




节点如果需要重启的话，需要去掉intial参数，否则会报错
```
etcd \
--name etcd0 \
--data-dir /tmp \
--advertise-client-urls http://c1:2379,http://c1:4001 \
--listen-client-urls http://0.0.0.0:2379,http://0.0.0.0:4001 \
--listen-peer-urls http://0.0.0.0:2380 > /tmp/etcd.log 2>&1
```

```
etcd \
--name etcd1 \
--data-dir /tmp \
--advertise-client-urls http://c2:2379,http://c2:4001 \
--listen-client-urls http://0.0.0.0:2379,http://0.0.0.0:4001 \
--listen-peer-urls http://0.0.0.0:2380 > /tmp/etcd.log 2>&1
```

etcd集群部署详解_服务器应用_Linux公社-Linux系统门户网站  http://www.linuxidc.com/Linux/2017-01/139665.htm

centos7安装etcd - 夢の殇 - 博客频道 - CSDN.NET  http://blog.csdn.net/dream_broken/article/details/52671344

etcd 集群搭建及常用场景分析 - zhojhon的博客 - 博客频道 - CSDN.NET  http://blog.csdn.net/u010511236/article/details/52386229

etcd集群部署与遇到的坑 - 暗痛 - 博客园
http://www.cnblogs.com/breg/p/5728237.html








通过Discovery自动发现来注册etcd服务
```
[root@c1 sysconfig]# curl https://discovery.etcd.io/new?size=2
https://discovery.etcd.io/aa75a98a9ca18d99cb7975e81185bb28 
```

C1上执行
```
etcd \
--name etcd0 \
--data-dir /tmp \
--advertise-client-urls http://c1:2379,http://c1:4001 \
--listen-client-urls http://0.0.0.0:2379,http://0.0.0.0:4001 \
--listen-peer-urls http://0.0.0.0:2380 \
--initial-advertise-peer-urls http://c1:2380 \
-discovery https://discovery.etcd.io/aa75a98a9ca18d99cb7975e81185bb28 > /tmp/etcd.log 2>&1 &
```

C2上执行
```
etcd \
--name etcd0 \
--data-dir /tmp \
--advertise-client-urls http://c2:2379,http://c2:4001 \
--listen-client-urls http://0.0.0.0:2379,http://0.0.0.0:4001 \
--listen-peer-urls http://0.0.0.0:2380 \
--initial-advertise-peer-urls http://c2:2380 \
-discovery https://discovery.etcd.io/aa75a98a9ca18d99cb7975e81185bb28 > /tmp/etcd.log 2>&1 &
```






















