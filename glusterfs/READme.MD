https://launchpad.net/~gluster

1. 增加源
```
root@ubuntu:~# add-apt-repository ppa:gluster/glusterfs-3.10 && apt-get update -y
```
2. 安装glusterfs-server
```
root@ubuntu:~# apt-get install glusterfs-server
```

3. 给服务器新增加一块硬盘，作为gluster存储介质 "Partition, Format and mount the bricks"
 

```
root@ubuntu:/mnt# fdisk /dev/sdb

Welcome to fdisk (util-linux 2.27.1).
Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.

Device does not contain a recognized partition table.
Created a new DOS disklabel with disk identifier 0x7ad47324.

Command (m for help): n
Partition type
   p   primary (0 primary, 0 extended, 4 free)
   e   extended (container for logical partitions)
Select (default p): p
Partition number (1-4, default 1): 
First sector (2048-251658239, default 2048): 
Last sector, +sectors or +size{K,M,G,T,P} (2048-251658239, default 251658239): 

Created a new partition 1 of type 'Linux' and of size 120 GiB.

Command (m for help): w
The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.


root@ubuntu:/mnt# fdisk -l
Disk /dev/sdb: 120 GiB, 128849018880 bytes, 251658240 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x7ad47324

Device     Boot Start       End   Sectors  Size Id Type
/dev/sdb1        2048 251658239 251656192  120G 83 Linux

Format the partition

root@ubuntu:/mnt# mkfs.xfs -i size=512 -n size=8192 /dev/sdb1
meta-data=/dev/sdb1              isize=512    agcount=4, agsize=7864256 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=1, sparse=0
data     =                       bsize=4096   blocks=31457024, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=8192   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=15359, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0


Mount the partition as a Gluster "brick"

root@ubuntu:/mnt# mkdir -p /glusterdata/sdb1 && mount /dev/sdb1 /glusterdata/sdb1 && mkdir -p /gluster/sdb1/brick1

Add an entry to /etc/fstab

root@ubuntu:/mnt# echo "/dev/sdb1 /glusterdata/sdb1 xfs defaults 0 0" >> /etc/fstab 

```
 

4. 建立集群，并加入各节点的机器
```
保证各主机的hosts文件统一
root@ubuntu:~# vim /etc/hosts

127.0.0.1       localhost
127.0.1.1       ubuntu

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
192.168.63.130  d1
192.168.63.131  d2
192.168.63.132  d3

在d1上执行
root@ubuntu:~# gluster peer probe d2
peer probe: success. 
root@ubuntu:~# gluster peer probe d3
peer probe: success. 

查看peer状态
root@ubuntu:~# gluster peer status
Number of Peers: 2

Hostname: d2
Uuid: 92b876fe-c614-4c51-9a40-194601bc2841
State: Peer in Cluster (Connected)

Hostname: d3
Uuid: f0223e0b-8ec9-4d54-b64e-d87ee605937e
State: Peer in Cluster (Connected)

Configure your Gluster volume

root@ubuntu:~# gluster volume create vg1 replica 2 transport tcp d1:/glusterdata/sdb1/vg1 d2:/glusterdata/sdb1/vg1

root@ubuntu:~# gluster volume create vg1 replica 2 transport tcp d1:/glusterdata/sdb1/vg1 d2:/glusterdata/sdb1/vg1
volume create: vg1: success: please start the volume to access data
root@ubuntu:~# gluster volume list
vg1
root@ubuntu:~# gluster volume info
 
Volume Name: vg1
Type: Replicate
Volume ID: 998e89ac-e52d-4eb8-87db-7e2d8f15330b
Status: Created
Snapshot Count: 0
Number of Bricks: 1 x 2 = 2
Transport-type: tcp
Bricks:
Brick1: d1:/glusterdata/sdb1/vg1
Brick2: d2:/glusterdata/sdb1/vg1
Options Reconfigured:
transport.address-family: inet
nfs.disable: on
root@ubuntu:~# gluster volume start vg1
volume start: vg1: success
root@ubuntu:~# gluster volume info vg1
 
Volume Name: vg1
Type: Replicate
Volume ID: 998e89ac-e52d-4eb8-87db-7e2d8f15330b
Status: Started
Snapshot Count: 0
Number of Bricks: 1 x 2 = 2
Transport-type: tcp
Bricks:
Brick1: d1:/glusterdata/sdb1/vg1
Brick2: d2:/glusterdata/sdb1/vg1
Options Reconfigured:
transport.address-family: inet
nfs.disable: on

增加brick

root@ubuntu:~# gluster volume add-brick vg1 d1:/glusterdata/sdb1/vg2 d2:/glusterdata/sdb1/vg2 d3:/glusterdata/sdb1/vg1 d3:/glusterdata/sdb1/vg2 force
volume add-brick: success

root@ubuntu:~# gluster volume info vg1
 
Volume Name: vg1
Type: Distributed-Replicate
Volume ID: 998e89ac-e52d-4eb8-87db-7e2d8f15330b
Status: Started
Snapshot Count: 0
Number of Bricks: 3 x 2 = 6
Transport-type: tcp
Bricks:
Brick1: d1:/glusterdata/sdb1/vg1
Brick2: d2:/glusterdata/sdb1/vg1
Brick3: d1:/glusterdata/sdb1/vg2
Brick4: d2:/glusterdata/sdb1/vg2
Brick5: d3:/glusterdata/sdb1/vg1
Brick6: d3:/glusterdata/sdb1/vg2
Options Reconfigured:
transport.address-family: inet
nfs.disable: on
```

4. 挂载glusterfs下的vg1至/mnt/gfs下
```
root@ubuntu:~# mount.glusterfs d1:/vg1 /mnt/gfs/
```

5. 测试gluster文件分布式
```
root@ubuntu:~# for i in $(seq -w 1000);do cp /etc/passwd /mnt/gfs/test-$i.txt;done

通过ansible查看各节点的目录状态
root@LEI:~/.ssh# ansible data -m shell -a 'ls /glusterdata/sdb1/vg* -R'
d1 | SUCCESS | rc=0 >>
/glusterdata/sdb1/vg1:
1
2
test-01.txt
test-04.txt
test-09.txt
test-11.txt
test-13.txt
test-14.txt
test-18.txt

/glusterdata/sdb1/vg1/1:

/glusterdata/sdb1/vg1/2:

/glusterdata/sdb1/vg2:
test-02.txt
test-06.txt
test-08.txt
test-17.txt
test-19.txt

d3 | SUCCESS | rc=0 >>
/glusterdata/sdb1/vg1:
test-03.txt
test-05.txt
test-07.txt
test-10.txt
test-12.txt
test-15.txt
test-16.txt
test-20.txt

/glusterdata/sdb1/vg2:
test-03.txt
test-05.txt
test-07.txt
test-10.txt
test-12.txt
test-15.txt
test-16.txt
test-20.txt

d2 | SUCCESS | rc=0 >>
/glusterdata/sdb1/vg1:
test-01.txt
test-04.txt
test-09.txt
test-11.txt
test-13.txt
test-14.txt
test-18.txt

/glusterdata/sdb1/vg2:
test-02.txt
test-06.txt
test-08.txt
test-17.txt
test-19.txt

使文件的分布能平衡
root@d1:~# gluster volume rebalance vg1 start

查看rebalance的状态
root@d2:~# gluster volume rebalance vg1 status
                                    Node Rebalanced-files          size       scanned      failures       skipped               status  run time in h:m:s
                               ---------      -----------   -----------   -----------   -----------   -----------         ------------     --------------
                               localhost                0        0Bytes             0             0             0            completed        0:00:00
                                      d1                0        0Bytes            23             0             0            completed        0:00:00
                                      d3                0        0Bytes            17             0             0            completed        0:00:00
volume rebalance: vg1: success




```

