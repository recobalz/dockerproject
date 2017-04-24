
```
graph LR
Admin-->Node1
Admin-->Node2
Admin-->Node3
```


主机名 | IP| Rule| xxx
---|---|---|---
admin | 192.168.61.132| ceph-deploy| 
node1 | 192.168.61.133| mon.node1| 
node2 | 192.168.61.134| osd.0| 
node3 | 192.168.61.135| osd.1| 

**在admin上，部署ceph部署工具（ceph-deploy）**

```
# yum install -y yum-utils && sudo yum-config-manager --add-repo https://dl.fedoraproject.org/pub/epel/7/x86_64/ && sudo yum install --nogpgcheck -y epel-release && sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7 && sudo rm /etc/yum.repos.d/dl.fedoraproject.org*
# vim /etc/yum.repos.d/ceph.repo
[ceph-noarch]
name=Ceph noarch packages
baseurl=http://download.ceph.com/rpm-jewel/el7/x86_64/
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://download.ceph.com/keys/release.asc
# yum update &&  yum install ceph-deploy

```

在所有ceph节点上创建一个用户ceph-deploy，用来部署ceph
```
# useradd -d /home/ceph-deploy -m ceph-deploy && passwd ceph-deploy
Changing password for user ceph-deploy.
New password: 
BAD PASSWORD: The password is a palindrome
Retype new password: 
passwd: all authentication tokens updated successfully.

sudo useradd -d /home/cephde -m cephde && sudo echo 111111 | passwd --stdin cephde
sudo useradd -d /home/cephde -m cephde && sudo echo cephde:111111 | chpasswd


# echo "ceph-deploy ALL = (root) NOPASSWD:ALL" | tee /etc/sudoers.d/ceph-deploy && chmod 0440 /etc/sudoers.d/ceph-deploy

# su - ceph-deploy
[ceph-deploy@admin ~]$ ssh-keygen 
Generating public/private rsa key pair.
Enter file in which to save the key (/home/ceph-deploy/.ssh/id_rsa): 
Created directory '/home/ceph-deploy/.ssh'.
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /home/ceph-deploy/.ssh/id_rsa.
Your public key has been saved in /home/ceph-deploy/.ssh/id_rsa.pub.
The key fingerprint is:
ba:34:9b:66:c0:8e:87:ad:c2:f1:88:4a:31:d3:22:a9 ceph-deploy@admin
The key's randomart image is:
+--[ RSA 2048]----+
|                 |
|                 |
|                 |
| ..              |
|o= o    S        |
|o.= o  .         |
|E.+= .+          |
|+oo.+.o=         |
|o..o o+          |
+-----------------+
$ ssh-copy-id node1
$ ssh-copy-id node2
$ ssh-copy-id node3

$ sudo ssh node1 getenforce
$ sudo ssh node2 getenforce
$ sudo ssh node3 getenforce

```

**开始创建集群**
```
在admin上执行
# ceph-deploy new node1
node1变成monitoer-nodes

安装Ceph
# ceph-deploy install admin node1 node2 node3
```
未完待续~~~
