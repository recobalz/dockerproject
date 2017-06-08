环境
两台centos7，安装docker，命名为k8s1，k8s2

准备工作
1. 准备镜像
```
```
2. 安装工具
```
```

3. 初始化集群
```
kubeadm init --kerbernets-version=v1.6.2 --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=192.168.63.158/24
```
