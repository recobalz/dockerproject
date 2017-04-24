两个节点，分别是C1和C2

安装和配置，已C1为例
```
curl -s -L git.io/weave -o /usr/local/bin/weave
chmod a+x /usr/local/bin/weave
eval $(weave env)
```

从C1上连接C2
```
weave launch c2
docker run --name a1 -ti weaveworks/ubuntu
```

从C2上连接C1
```
weave launch c2
docker run --name a2 -ti weaveworks/ubuntu
```

测试链接情况
```
......
```

Docker学习笔记 — Weave实现跨主机容器互联 - Just for fun - 博客频道 - CSDN.NET  http://blog.csdn.net/wangtaoking1/article/details/45244525
Using Weave Net - Weaveworks  https://www.weave.works/docs/net/latest/using-weave/
