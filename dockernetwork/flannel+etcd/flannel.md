配置flannel

我们直接使用的yum安装的flannle，安装好后会生成 /usr/lib/systemd/system/flanneld.service 配置文件。
```
[Unit]
Description=Flanneld overlay address etcd agent
After=network.target
After=network-online.target
Wants=network-online.target
After=etcd.service
Before=docker.service

[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/flanneld
EnvironmentFile=-/etc/sysconfig/docker-network
ExecStart=/usr/bin/flanneld-start $FLANNEL_OPTIONS
ExecStartPost=/usr/libexec/flannel/mk-docker-opts.sh -k DOCKER_NETWORK_OPTIONS -d /run/flannel/docker
Restart=on-failure

[Install]
WantedBy=multi-user.target
RequiredBy=docker.service
```
可以看到flannel环境变量配置文件在 /etc/sysconfig/flanneld 。
```
# Flanneld configuration options  

# etcd url location.  Point this to the server where etcd runs
FLANNEL_ETCD_ENDPOINTS="http://sz-pg-oam-docker-test-001.tendcloud.com:2379"

# etcd config key.  This is the configuration key that flannel queries
# For address range assignment
FLANNEL_ETCD_PREFIX="/kube-centos/network"

# Any additional options that you want to pass
#FLANNEL_OPTIONS=""
```
etcd 的地址 FLANNEL_ETCD_ENDPOINT
etcd查询的目录，包含docker的IP地址段配置。 FLANNEL_ETCD_PREFIX
在etcd中创建网络配置

执行下面的命令为docker分配IP地址段。
```
etcdctl mkdir /kube-centos/network
etcdctl mk /kube-centos/network/config "{ \"Network\": \"172.30.0.0/16\", \"SubnetLen\": 24, \"Backend\": { \"Type\": \"vxlan\" } }"
```

配置Docker

Flannel的 文档 中有写 Docker Integration ：

Docker daemon accepts --bip argument to configure the subnet of the docker0 bridge. It also accepts --mtu to set the MTU for docker0 and veth devices that it will be creating. Since flannel writes out the acquired subnet and MTU values into a file, the script starting Docker can source in the values and pass them to Docker daemon:
```
source /run/flannel/subnet.env
docker daemon --bip=${FLANNEL_SUBNET} --mtu=${FLANNEL_MTU} &
```
Systemd users can use EnvironmentFile directive in the .service file to pull in /run/flannel/subnet.env

下载flannel github release中的tar包，解压后会获得一个 mk-docker-opts.sh 文件。

这个文件是用来 Generate Docker daemon options based on flannel env file 。

执行 ./mk-docker-opts.sh -i 将会生成如下两个文件环境变量文件。
```
/run/flannel/subnet.env

FLANNEL_NETWORK=172.30.0.0/16
FLANNEL_SUBNET=172.30.46.1/24
FLANNEL_MTU=1450
FLANNEL_IPMASQ=false
/run/docker_opts.env

DOCKER_OPT_BIP="--bip=172.30.46.1/24"
DOCKER_OPT_IPMASQ="--ip-masq=true"
DOCKER_OPT_MTU="--mtu=1450"
```
设置docker0网桥的IP地址
```
source /run/flannel/subnet.env
ifconfig docker0 $FLANNEL_SUBNET
```
这样docker0和flannel网桥会在同一个子网中，如
```
6: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN 
    link/ether 02:42:da:bf:83:a2 brd ff:ff:ff:ff:ff:ff
    inet 172.30.38.1/24 brd 172.30.38.255 scope global docker0
       valid_lft forever preferred_lft forever
7: flannel.1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN 
    link/ether 9a:29:46:61:03:44 brd ff:ff:ff:ff:ff:ff
    inet 172.30.38.0/32 scope global flannel.1
       valid_lft forever preferred_lft forever
```
现在就可以重启docker了。

重启了docker后还要重启kubelet，这时又遇到问题，kubelet启动失败。报错：
```
Mar 31 16:44:41 sz-pg-oam-docker-test-002.tendcloud.com kubelet[81047]: error: failed to run Kubelet: failed to create kubelet: misconfiguration: kubelet cgroup driver: "cgroupfs" is different from docker cgroup driver: "systemd"
```
这是kubelet与docker的 cgroup driver 不一致导致的，kubelet启动的时候有个 —cgroup-driver 参数可以指定为”cgroupfs”或者“systemd”。

```
--cgroup-driver string                                    Driver that the kubelet uses to manipulate cgroups on the host.  Possible values: 'cgroupfs', 'systemd' (default "cgroupfs")
```
启动flannel
```
systemctl daemon-reload
systemctl start flanneld
systemctl status flanneld
```
重新登录这三台主机，可以看到每台主机都多了一个IP。

#启动nginx的pod
```
kubectl run nginx --replicas=2 --labels="run=load-balancer-example" --image=sz-pg-oam-docker-hub-001.tendcloud.com/library/nginx:1.9  --port=8080
#创建名为example-service的服务
kubectl expose deployment nginx --type=NodePort --name=example-service
#查看状态
kubectl get deployments nginx
kubectl describe deployments nginx
kubectl get replicasets
kubectl describe replicasets
kubectl describe svc example-service
###################################################
Name:			example-service
Namespace:		default
Labels:			run=load-balancer-example
Annotations:		<none>
Selector:		run=load-balancer-example
Type:			NodePort
IP:			10.254.124.145
Port:			<unset>	8080/TCP
NodePort:		<unset>	30554/TCP
Endpoints:		172.30.38.2:8080,172.30.46.2:8080
Session Affinity:	None
Events:			<none>
```
虚拟地址

Kubernetes中的Service了使用了虚拟地址；该地址无法ping通过，但可以访问其端口。通过下面的命令可以看到，该虚拟地址是若干条iptables的规则。到10.254.124.145:8080端口的请求会被重定向到172.30.38.2或172.30.46.2的8080端口。这些规则是由kube-proxy生成；如果需要某台机器可以访问Service，则需要在该主机启动kube-proxy。

查看service的iptables
```
$iptables-save|grep example-service
-A KUBE-NODEPORTS -p tcp -m comment --comment "default/example-service:" -m tcp --dport 30554 -j KUBE-MARK-MASQ
-A KUBE-NODEPORTS -p tcp -m comment --comment "default/example-service:" -m tcp --dport 30554 -j KUBE-SVC-BR4KARPIGKMRMN3E
-A KUBE-SEP-65MX5SGLQRLS77WG -s 172.30.46.2/32 -m comment --comment "default/example-service:" -j KUBE-MARK-MASQ
-A KUBE-SEP-65MX5SGLQRLS77WG -p tcp -m comment --comment "default/example-service:" -m tcp -j DNAT --to-destination 172.30.46.2:8080
-A KUBE-SEP-G3W5BQFRHWIMSQQY -s 172.30.38.2/32 -m comment --comment "default/example-service:" -j KUBE-MARK-MASQ
-A KUBE-SEP-G3W5BQFRHWIMSQQY -p tcp -m comment --comment "default/example-service:" -m tcp -j DNAT --to-destination 172.30.38.2:8080
-A KUBE-SERVICES -d 10.254.124.145/32 -p tcp -m comment --comment "default/example-service: cluster IP" -m tcp --dport 8080 -j KUBE-SVC-BR4KARPIGKMRMN3E
-A KUBE-SVC-BR4KARPIGKMRMN3E -m comment --comment "default/example-service:" -m statistic --mode random --probability 0.50000000000 -j KUBE-SEP-G3W5BQFRHWIMSQQY
-A KUBE-SVC-BR4KARPIGKMRMN3E -m comment --comment "default/example-service:" -j KUBE-SEP-65MX5SGLQRLS77WG
```
查看clusterIP的iptables
```
$iptables -t nat -nL|grep 10.254
KUBE-SVC-NPX46M4PTMTKRN6Y  tcp  --  0.0.0.0/0            10.254.0.1           /* default/kubernetes:https cluster IP */ tcp dpt:443
KUBE-SVC-BR4KARPIGKMRMN3E  tcp  --  0.0.0.0/0            10.254.198.44        /* default/example-service: cluster IP */ tcp dpt:8080
```
可以看到在PREROUTING环节，k8s设置了一个target: KUBE-SERVICES。而KUBE-SERVICES下面又设置了许多target，一旦destination和dstport匹配，就会沿着chain进行处理。

比如：当我们在pod网络curl 10.254.198.44 8080时，匹配到下面的KUBE-SVC-BR4KARPIGKMRMN3E target：
```
KUBE-SVC-BR4KARPIGKMRMN3E  tcp  --  0.0.0.0/0            10.254.198.44        /* default/example-service: cluster IP */ tcp dpt:8080
```