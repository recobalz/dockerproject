> kubernetes 1.5.0 , 配置文档


# 1 初始化环境


## 1.1 环境：

 

| 节 点  |      I P      |
|--------|-------------|
|node-1|10.6.0.140|
|node-2|10.6.0.187|
|node-3|10.6.0.188|


## 1.2 设置hostname

hostnamectl --static set-hostname hostname
 

|       I P     | hostname |
|-------------|-------------|
|10.6.0.140|k8s-node-1|
|10.6.0.187|k8s-node-2|
|10.6.0.188|k8s-node-3|

 


## 1.3 配置 hosts

```
vi /etc/hosts
```

|     I P       | hostname |
|-------------|-------------|
|10.6.0.140|k8s-node-1|
|10.6.0.187|k8s-node-2|
|10.6.0.188|k8s-node-3|

 

# 2.0 部署 kubernetes master

 

## 2.1 添加yum

 


# 使用我朋友的 yum 源，嘿嘿

cat <<EOF> /etc/yum.repos.d/kubernetes.repo
[mritdrepo]
name=Mritd Repository
baseurl=https://yum.mritd.me/centos/7/x86_64
enabled=1
gpgcheck=1
gpgkey=https://cdn.mritd.me/keys/rpm.public.key
EOF



yum makecache

yum install -y socat kubelet kubeadm kubectl kubernetes-cni

 


## 2.2 安装docker

 

wget -qO- https://get.docker.com/ | sh


systemctl enable docker
systemctl start docker
 
vim /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
sysctl -p /etc/sysctl.d/k8s.conf

## 2.3 安装 etcd 集群


yum -y install etcd

# 创建etcd data 目录

mkdir -p /opt/etcd/data

chown -R etcd:etcd /opt/etcd/


# 修改配置文件，/etc/etcd/etcd.conf 需要修改如下参数：


ETCD_NAME=etcd1
ETCD_DATA_DIR="/opt/etcd/data/etcd1.etcd"
ETCD_LISTEN_PEER_URLS="http://10.6.0.140:2380"
ETCD_LISTEN_CLIENT_URLS="http://10.6.0.140:2379,http://127.0.0.1:2379"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://10.6.0.140:2380"
ETCD_INITIAL_CLUSTER="etcd1=http://10.6.0.140:2380,etcd2=http://10.6.0.187:2380,etcd3=http://10.6.0.188:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="k8s-etcd-cluster"
ETCD_ADVERTISE_CLIENT_URLS="http://10.6.0.140:2379"

 

 

# 修改 etcd 启动文件

sed -i 's/\\\"${ETCD_LISTEN_CLIENT_URLS}\\\"/\\\"${ETCD_LISTEN_CLIENT_URLS}\\\" --listen-client-urls=\\\"${ETCD_LISTEN_CLIENT_URLS}\\\" --advertise-client-urls=\\\"${ETCD_ADVERTISE_CLIENT_URLS}\\\" --initial-cluster-token=\\\"${ETCD_INITIAL_CLUSTER_TOKEN}\\\" --initial-cluster=\\\"${ETCD_INITIAL_CLUSTER}\\\" --initial-cluster-state=\\\"${ETCD_INITIAL_CLUSTER_STATE}\\\"/g' /usr/lib/systemd/system/etcd.service
 


 


# 启动 etcd

systemctl enable etcd

systemctl start etcd

systemctl status etcd


# 查看集群状态

etcdctl cluster-health

 

 

## 2.4 下载镜像

 


images=(kube-proxy-amd64:v1.5.1 kube-discovery-amd64:1.0 kubedns-amd64:1.9 kube-scheduler-amd64:v1.5.1 kube-controller-manager-amd64:v1.5.1 kube-apiserver-amd64:v1.5.1 etcd-amd64:3.0.14-kubeadm kube-dnsmasq-amd64:1.4 exechealthz-amd64:1.2 pause-amd64:3.0 kubernetes-dashboard-amd64:v1.5.0 dnsmasq-metrics-amd64:1.0)
for imageName in ${images[@]} ; do
  docker pull jicki/$imageName
  docker tag jicki/$imageName gcr.io/google_containers/$imageName
  docker rmi jicki/$imageName
done

```

```
# 如果速度很慢，可配置一下加速

docker 启动文件 增加 --registry-mirror="http://b438f72b.m.daocloud.io"

```

 

 

 


## 2.4 启动 kubernetes

 

```
systemctl enable kubelet
systemctl start kubelet
```
 

 

## 2.5 创建集群

 


```
kubeadm init --api-advertise-addresses=10.6.0.140 \
--external-etcd-endpoints=http://10.6.0.140:2379,http://10.6.0.187:2379,http://10.6.0.188:2379 \
--use-kubernetes-version v1.5.1 \
--pod-network-cidr 10.244.0.0/16

```

```
Flag --external-etcd-endpoints has been deprecated, this flag will be removed when componentconfig exists
[kubeadm] WARNING: kubeadm is in alpha, please do not use it for production clusters.
[preflight] Running pre-flight checks
[preflight] Starting the kubelet service
[init] Using Kubernetes version: v1.5.1
[tokens] Generated token: "c53ef2.d257d49589d634f0"
[certificates] Generated Certificate Authority key and certificate.
[certificates] Generated API Server key and certificate
[certificates] Generated Service Account signing keys
[certificates] Created keys and certificates in "/etc/kubernetes/pki"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/kubelet.conf"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/admin.conf"
[apiclient] Created API client, waiting for the control plane to become ready
[apiclient] All control plane components are healthy after 15.299235 seconds
[apiclient] Waiting for at least one node to register and become ready
[apiclient] First node is ready after 1.002937 seconds
[apiclient] Creating a test deployment
[apiclient] Test deployment succeeded
[token-discovery] Created the kube-discovery deployment, waiting for it to become ready
[token-discovery] kube-discovery is ready after 2.502881 seconds
[addons] Created essential addon: kube-proxy
[addons] Created essential addon: kube-dns

Your Kubernetes master has initialized successfully!

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
    http://kubernetes.io/docs/admin/addons/

You can now join any number of machines by running the following on each node:

kubeadm join --token=c53ef2.d257d49589d634f0 10.6.0.140


```

 

 

## 2.6 记录 token
 

You can now join any number of machines by running the following on each node:

kubeadm join --token=c53ef2.d257d49589d634f0 10.6.0.140
 

 

## 2.7 配置网络

 

 


```
# 建议先下载镜像，否则容易下载不到

docker pull quay.io/coreos/flannel-git:v0.6.1-28-g5dde68d-amd64

# 或者这样

docker pull jicki/flannel-git:v0.6.1-28-g5dde68d-amd64
docker tag jicki/flannel-git:v0.6.1-28-g5dde68d-amd64 quay.io/coreos/flannel-git:v0.6.1-28-g5dde68d-amd64
docker rmi jicki/flannel-git:v0.6.1-28-g5dde68d-amd64


```


```
# http://kubernetes.io/docs/admin/addons/  这里有多种网络模式，选择一种

# 这里选择 Flannel  选择 Flannel  init 时必须配置 --pod-network-cidr

kubectl create -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

```

 

 

## 2.8 检查 kubelet 状态

 

systemctl status kubelet
 

 

 


# 3.0 部署 kubernetes node


## 3.1 安装docker

 


```
wget -qO- https://get.docker.com/ | sh


systemctl enable docker
systemctl start docker
```

 

 

## 3.2 下载镜像


```
images=(kube-proxy-amd64:v1.5.1 kube-discovery-amd64:1.0 kubedns-amd64:1.9 kube-scheduler-amd64:v1.5.1 kube-controller-manager-amd64:v1.5.1 kube-apiserver-amd64:v1.5.1 etcd-amd64:3.0.14-kubeadm kube-dnsmasq-amd64:1.4 exechealthz-amd64:1.2 pause-amd64:3.0 kubernetes-dashboard-amd64:v1.5.0 dnsmasq-metrics-amd64:1.0)
for imageName in ${images[@]} ; do
  docker pull jicki/$imageName
  docker tag jicki/$imageName gcr.io/google_containers/$imageName
  docker rmi jicki/$imageName
done

```

 


## 3.3 启动 kubernetes

 

systemctl enable kubelet
systemctl start kubelet
 


## 3.4 加入集群

 

kubeadm join --token=c53ef2.d257d49589d634f0 10.6.0.140
 

Node join complete:
* Certificate signing request sent to master and response
  received.
* Kubelet informed of new secure connection details.

Run 'kubectl get nodes' on the master to see this machine join.
 

 

## 3.5 查看集群状态

 

[root@k8s-node-1 ~]#kubectl get node
NAME         STATUS         AGE
k8s-node-1   Ready,master   27m
k8s-node-2   Ready          6s
k8s-node-3   Ready          9s
 


## 3.6 查看服务状态

 


[root@k8s-node-1 ~]#kubectl get pods --all-namespaces
NAMESPACE     NAME                                 READY     STATUS    RESTARTS   AGE
kube-system   dummy-2088944543-qrp68               1/1       Running   1          1h
kube-system   kube-apiserver-k8s-node-1            1/1       Running   2          1h
kube-system   kube-controller-manager-k8s-node-1   1/1       Running   2          1h
kube-system   kube-discovery-1769846148-g2lpc      1/1       Running   1          1h
kube-system   kube-dns-2924299975-xbhv4            4/4       Running   3          1h
kube-system   kube-flannel-ds-39g5n                2/2       Running   2          1h
kube-system   kube-flannel-ds-dwc82                2/2       Running   2          1h
kube-system   kube-flannel-ds-qpkm0                2/2       Running   2          1h
kube-system   kube-proxy-16c50                     1/1       Running   2          1h
kube-system   kube-proxy-5rkc8                     1/1       Running   2          1h
kube-system   kube-proxy-xwrq0                     1/1       Running   2          1h
kube-system   kube-scheduler-k8s-node-1            1/1       Running   2          1h

 

 

 


# 4.0 设置 kubernetes

## 4.1 其他主机控制集群

 


```
# 备份master节点的 配置文件

/etc/kubernetes/admin.conf

# 保存至 其他电脑, 通过执行配置文件控制集群

kubectl --kubeconfig ./admin.conf get nodes

```

 


## 4.2 配置dashboard

 


```
#下载 yaml 文件, 直接导入会去官方拉取images

curl -O https://rawgit.com/kubernetes/dashboard/master/src/deploy/kubernetes-dashboard.yaml


#编辑 yaml 文件

vi kubernetes-dashboard.yaml

image: gcr.io/google_containers/kubernetes-dashboard-amd64:v1.4.0

修改为

image: gcr.io/google_containers/kubernetes-dashboard-amd64:v1.5.0


imagePullPolicy: Always

修改为

imagePullPolicy: IfNotPresent

```


```
kubectl create -f ./kubernetes-dashboard.yaml

deployment "kubernetes-dashboard" created
service "kubernetes-dashboard" created
```


```
# 查看 NodePort ，既外网访问端口

kubectl describe svc kubernetes-dashboard --namespace=kube-system

NodePort:               <unset> 31736/TCP

```


```
# 访问 dashboard

http://10.6.0.140:31736

```

 

 

 

 


# 5.0 kubernetes 应用部署


## 5.1 部署一个 nginx rc


> 编写 一个 nginx yaml

 


```
apiVersion: v1 
kind: ReplicationController 
metadata: 
  name: nginx-rc 
spec: 
  replicas: 2 
  selector: 
    name: nginx 
  template: 
    metadata: 
      labels: 
        name: nginx 
    spec: 
      containers: 
        - name: nginx 
          image: nginx:alpine
          imagePullPolicy: IfNotPresent
          ports: 
            - containerPort: 80
```

```
[root@k8s-node-1 ~]#kubectl get rc
NAME       DESIRED   CURRENT   READY     AGE
nginx-rc   2         2         2         2m


[root@k8s-node-1 ~]#kubectl get pod -o wide
NAME             READY     STATUS    RESTARTS   AGE       IP          NODE
nginx-rc-2s8k9   1/1       Running   0          10m       10.32.0.3   k8s-node-1
nginx-rc-s16cm   1/1       Running   0          10m       10.40.0.1   k8s-node-2

 

 

> 编写一个 nginx service 让集群内部容器可以访问 (ClusterIp)

 


```
apiVersion: v1 
kind: Service 
metadata: 
  name: nginx-svc 
spec: 
  ports: 
    - port: 80
      targetPort: 80
      protocol: TCP 
  selector: 
    name: nginx
```


```
[root@k8s-node-1 ~]#kubectl create -f nginx-svc.yaml 
service "nginx-svc" created


[root@k8s-node-1 ~]#kubectl get svc -o wide
NAME         CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE       SELECTOR
kubernetes   10.0.0.1      <none>        443/TCP   2d        <none>
nginx-svc    10.6.164.79   <none>        80/TCP    29s       name=nginx

```



> 编写一个 curl 的pods

```
apiVersion: v1
kind: Pod
metadata:
  name: curl
spec:
  containers:
  - name: curl
    image: radial/busyboxplus:curl
    command:
    - sh
    - -c
    - while true; do sleep 1; done
```


```
# 测试pods 内部通信
[root@k8s-node-1 ~]#kubectl exec curl curl nginx
```



```
# 在任何node节点中，可使用ip访问

[root@k8s-node-2 ~]# curl 10.6.164.79
[root@k8s-node-3 ~]# curl 10.6.164.79

```

 

 

> 编写一个 nginx service 让外部可以访问 (NodePort)

 


```
apiVersion: v1
kind: Service
metadata:
  name: nginx-svc-node
spec:
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
  type: NodePort
  selector:
    name: nginx
```


```
[root@k8s-node-1 ~]#kubectl get svc -o wide
NAME             CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE       SELECTOR
kubernetes       10.0.0.1       <none>        443/TCP   2d        <none>
nginx-svc        10.6.164.79    <none>        80/TCP    29m       name=nginx
nginx-svc-node   10.12.95.227   <nodes>       80/TCP    17s       name=nginx


[root@k8s-node-1 ~]#kubectl describe svc nginx-svc-node |grep NodePort
Type:                   NodePort
NodePort:               <unset> 32669/TCP
```



```
# 使用 ALL node节点物理IP + 端口访问

http://10.6.0.140:32669

http://10.6.0.187:32669

http://10.6.0.188:32669
```

 

 

 


## 5.2 部署一个 zookeeper 集群


> 编写 一个 zookeeper-cluster.yaml

 


```
apiVersion: extensions/v1beta1
kind: Deployment 
metadata: 
  name: zookeeper-1
spec: 
  replicas: 1
  template: 
    metadata: 
      labels: 
        name: zookeeper-1 
    spec: 
      containers: 
        - name: zookeeper-1
          image: zk:alpine 
          imagePullPolicy: IfNotPresent
          env:
          - name: NODE_ID
            value: "1"
          - name: NODES
            value: "0.0.0.0,zookeeper-2,zookeeper-3"
          ports:
          - containerPort: 2181

---

apiVersion: extensions/v1beta1 
kind: Deployment
metadata:
  name: zookeeper-2
spec:
  replicas: 1
  template:
    metadata:
      labels:
        name: zookeeper-2
    spec:
      containers:
        - name: zookeeper-2
          image: zk:alpine
          imagePullPolicy: IfNotPresent
          env:
          - name: NODE_ID
            value: "2"
          - name: NODES
            value: "zookeeper-1,0.0.0.0,zookeeper-3"
          ports:
          - containerPort: 2181

---

apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: zookeeper-3
spec:
  replicas: 1
  template:
    metadata:
      labels:
        name: zookeeper-3
    spec:
      containers:
        - name: zookeeper-3
          image: zk:alpine
          imagePullPolicy: IfNotPresent
          env:
          - name: NODE_ID
            value: "3"
          - name: NODES
            value: "zookeeper-1,zookeeper-2,0.0.0.0"
          ports:
          - containerPort: 2181
---

apiVersion: v1 
kind: Service 
metadata: 
  name: zookeeper-1 
  labels:
    name: zookeeper-1
spec: 
  ports: 
    - name: client
      port: 2181
      protocol: TCP
    - name: followers
      port: 2888
      protocol: TCP
    - name: election
      port: 3888
      protocol: TCP
  selector: 
    name: zookeeper-1

---

apiVersion: v1 
kind: Service 
metadata: 
  name: zookeeper-2
  labels:
    name: zookeeper-2
spec: 
  ports: 
    - name: client
      port: 2181
      protocol: TCP
    - name: followers
      port: 2888
      protocol: TCP
    - name: election
      port: 3888
      protocol: TCP
  selector: 
    name: zookeeper-2

---

apiVersion: v1 
kind: Service 
metadata: 
  name: zookeeper-3
  labels:
    name: zookeeper-3
spec: 
  ports: 
    - name: client
      port: 2181
      protocol: TCP
    - name: followers
      port: 2888
      protocol: TCP
    - name: election
      port: 3888
      protocol: TCP
  selector: 
    name: zookeeper-3
    
```


```
[root@k8s-node-1 ~]#kubectl create -f zookeeper-cluster.yaml --record



[root@k8s-node-1 ~]#kubectl get pods -o wide
NAME                           READY     STATUS    RESTARTS   AGE       IP          NODE
zookeeper-1-2149121414-cfyt4   1/1       Running   0          51m       10.32.0.3   k8s-node-2
zookeeper-2-2653289864-0bxee   1/1       Running   0          51m       10.40.0.1   k8s-node-3
zookeeper-3-3158769034-5csqy   1/1       Running   0          51m       10.40.0.2   k8s-node-3


[root@k8s-node-1 ~]#kubectl get deployment -o wide    
NAME          DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
zookeeper-1   1         1         1            1           51m
zookeeper-2   1         1         1            1           51m
zookeeper-3   1         1         1            1           51m


[root@k8s-node-1 ~]#kubectl get svc -o wide
NAME          CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE       SELECTOR
zookeeper-1   10.8.111.19    <none>        2181/TCP,2888/TCP,3888/TCP   51m       name=zookeeper-1
zookeeper-2   10.6.10.124    <none>        2181/TCP,2888/TCP,3888/TCP   51m       name=zookeeper-2
zookeeper-3   10.0.146.143   <none>        2181/TCP,2888/TCP,3888/TCP   51m       name=zookeeper-3

 

 

## 5.3 部署一个 kafka 集群


> 编写 一个 kafka-cluster.yaml

 


```

apiVersion: extensions/v1beta1
kind: Deployment 
metadata: 
  name: kafka-deployment-1
spec: 
  replicas: 1
  template: 
    metadata: 
      labels: 
        name: kafka-1 
    spec: 
      containers: 
        - name: kafka-1
          image: kafka:alpine 
          imagePullPolicy: IfNotPresent
          env:
          - name: NODE_ID
            value: "1"
          - name: ZK_NODES
            value: "zookeeper-1,zookeeper-2,zookeeper-3"
          ports:
          - containerPort: 9092

---

apiVersion: extensions/v1beta1 
kind: Deployment
metadata:
  name: kafka-deployment-2
spec:
  replicas: 1
  template:
    metadata:
      labels:
        name: kafka-2  
    spec:
      containers:
        - name: kafka-2
          image: kafka:alpine
          imagePullPolicy: IfNotPresent
          env:
          - name: NODE_ID
            value: "2"
          - name: ZK_NODES
            value: "zookeeper-1,zookeeper-2,zookeeper-3"
          ports:
          - containerPort: 9092

---

apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: kafka-deployment-3
spec:
  replicas: 1
  template:
    metadata:
      labels:
        name: kafka-3  
    spec:
      containers:
        - name: kafka-3
          image: kafka:alpine
          imagePullPolicy: IfNotPresent
          env:
          - name: NODE_ID
            value: "3"
          - name: ZK_NODES
            value: "zookeeper-1,zookeeper-2,zookeeper-3"
          ports:
          - containerPort: 9092

---

apiVersion: v1 
kind: Service 
metadata: 
  name: kafka-1 
  labels:
    name: kafka-1
spec: 
  ports: 
    - name: client
      port: 9092
      protocol: TCP
  selector: 
    name: kafka-1

---

apiVersion: v1 
kind: Service 
metadata: 
  name: kafka-2
  labels:
    name: kafka-2
spec: 
  ports: 
    - name: client
      port: 9092
      protocol: TCP
  selector: 
    name: kafka-2

---

apiVersion: v1 
kind: Service 
metadata: 
  name: kafka-3
  labels:
    name: kafka-3
spec: 
  ports: 
    - name: client
      port: 9092
      protocol: TCP
  selector: 
    name: kafka-3

```

 

 

 

 

 


# FAQ:


## kube-discovery error

 

    failed to create "kube-discovery" deployment [deployments.extensions "kube-discovery" already exists]
    

kubeadm reset

kubeadm init