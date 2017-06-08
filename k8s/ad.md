root@node1 ~]# cd k8s/
[root@node1 k8s]# ls
[root@node1 k8s]# wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64

[root@node1 k8s]# chmod +x cfssl_linux-amd64 
[root@node1 k8s]# mv cfssl_linux-amd64 /local/bin/cfssl

[root@node1 k8s]# wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64
[root@node1 k8s]# chmod +x cfssl-certinfo_linux-amd64
[root@node1 k8s]# mv cfssl-certinfo_linux-amd64 /local/bin/cfssl-certinfo