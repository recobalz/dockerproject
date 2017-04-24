# 一、openvpn原理

# 二、安装openvpn #

# 三、制作相关证书 #

    3.1 制作CA证书
    3.2 制作Server端证书
    3.3 制作Client端证书

# 四、配置Server端 #

# 五、配置Client端 #

    5.1 在Windows 系统上
    5.2 在OpenVPN server上
    5.3 配置client段配置文件 


### 一、openvpn原理 ###

openvpn通过使用公开密钥（非对称密钥，加密解密使用不同的key，一个称为Publice key，另外一个是Private key）对数据进行加密的。这种方式称为TLS加密

openvpn使用TLS加密的工作过程是，首先VPN Sevrver端和VPN Client端要有相同的CA证书，双方通过交换证书验证双方的合法性，用于决定是否建立VPN连接。

然后使用对方的CA证书，把自己目前使用的数据加密方法加密后发送给对方，由于使用的是对方CA证书加密，所以只有对方CA证书对应的Private key才能解密该数据，这样就保证了此密钥的安全性，并且此密钥是定期改变的，对于窃听者来说，可能还没有破解出此密钥，VPN通信双方可能就已经更换密钥了。

### 二、安装openvpn ###

yum方式安装，此处统一使用aliyun中centos和epel源

    # rm /etc/yum.repos.d/* -fr
    # vim /etc/yum.repos.d/ali.repo

    [centos6]
    name=centeros6 base
    baseurl=http://mirrors.aliyun.com/centos/6/os/x86_64/
    gpgcheck=0
    [epel]
    name=epel base
    baseurl=http://mirrors.aliyun.com/epel/6/x86_64
    gpgcheck=0

为避免出现错误，关闭selinux，并开启网卡转发功能
    
    # setenforce 0;sed -i 's/SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
    # echo "1" > /proc/sys/net/ipv4/ip_forward  

开始安装openvpn server
```
    # yum install -y openvpn
```
openvpn安装完毕后，我们来查看openvpn的版本，如下：


    # openvpn --version
    OpenVPN 2.3.10 x86_64-redhat-linux-gnu [SSL (OpenSSL)] [LZO] [EPOLL] [PKCS11] [MH] [IPv6] built on Jan  4 2016
    library versions: OpenSSL 1.0.1e-fips 11 Feb 2013, LZO 2.03
    Originally developed by James Yonan
    Copyright (C) 2002-2010 OpenVPN Technologies, Inc. <sales@openvpn.net>
    Compile time defines: enable_crypto=yes enable_crypto_ofb_cfb=yes enable_debug=yes enable_def_auth=yes enable_dlopen=unknown enable_dlopen_self=unknown enable_dlopen_self_static=unknown enable_fast_install=yes enable_fragment=yes enable_http_proxy=yes enable_iproute2=yes enable_libtool_lock=yes enable_lzo=yes enable_lzo_stub=no enable_management=yes enable_multi=yes enable_multihome=yes enable_pam_dlopen=no enable_password_save=yes enable_pedantic=no enable_pf=yes enable_pkcs11=yes enable_plugin_auth_pam=yes enable_plugin_down_root=yes enable_plugins=yes enable_port_share=yes enable_pthread=yes enable_selinux=no enable_server=yes enable_shared=yes enable_shared_with_static_runtimes=no enable_small=no enable_socks=yes enable_ssl=yes enable_static=yes enable_strict=no enable_strict_options=no enable_systemd=no enable_win32_dll=yes enable_x509_alt_username=yes with_crypto_library=openssl with_gnu_ld=yes with_iproute_path=/sbin/ip with_mem_check=no with_plugindir='$(libdir)/openvpn/plugins' with_sysroot=no

openvpn安装完毕后，我们再来安装easy-rsa。

easy-rsa是用来制作openvpn相关证书的。

安装easy-rsa，使用如下命令：

    # yum install -y easy-rsa
查看easy-rsa安装的文件，如下：
```
    [root@centos6 openvpn]# rpm -ql easy-rsa
    /usr/share/doc/easy-rsa-2.2.2
    /usr/share/doc/easy-rsa-2.2.2/COPYING
    /usr/share/doc/easy-rsa-2.2.2/COPYRIGHT.GPL
    /usr/share/doc/easy-rsa-2.2.2/doc
    /usr/share/doc/easy-rsa-2.2.2/doc/Makefile.am
    /usr/share/doc/easy-rsa-2.2.2/doc/README-2.0
    /usr/share/easy-rsa
    /usr/share/easy-rsa/2.0
    /usr/share/easy-rsa/2.0/build-ca
    /usr/share/easy-rsa/2.0/build-dh
    /usr/share/easy-rsa/2.0/build-inter
    /usr/share/easy-rsa/2.0/build-key
    /usr/share/easy-rsa/2.0/build-key-pass
    /usr/share/easy-rsa/2.0/build-key-pkcs12
    /usr/share/easy-rsa/2.0/build-key-server
    /usr/share/easy-rsa/2.0/build-req
    /usr/share/easy-rsa/2.0/build-req-pass
    /usr/share/easy-rsa/2.0/clean-all
    /usr/share/easy-rsa/2.0/inherit-inter
    /usr/share/easy-rsa/2.0/list-crl
    /usr/share/easy-rsa/2.0/openssl-0.9.6.cnf
    /usr/share/easy-rsa/2.0/openssl-0.9.8.cnf
    /usr/share/easy-rsa/2.0/openssl-1.0.0.cnf
    /usr/share/easy-rsa/2.0/pkitool
    /usr/share/easy-rsa/2.0/revoke-full
    /usr/share/easy-rsa/2.0/sign-req
    /usr/share/easy-rsa/2.0/vars
    /usr/share/easy-rsa/2.0/whichopensslcnf
```
我们可以看到easy-rsa已经安装到/usr/share/easy-rsa/目录下。



### 三、制作相关证书 ###
根据第一章节openvpn的工作原理，我们可以知道openvpn的证书分为三部分：CA证书、Server端证书、Client端证书。
下面我们通过easy-rsa分别对其进行制作。
##### 3.1 制作CA证书 #####
openvpn与easy-rsa安装完毕后，我们可以直接在/usr/share/easy-rsa/2.0 制作相关的证书，但是为了后续的管理证书的方便，我们需要在/etc/openvpn/目录下创建easy-rsa文件夹，
然后把/usr/share/easy-rsa/目录下的所有文件全部复制到/etc/openvpn/easy-rsa/下：
```
    # mkdir /etc/openvpn/easy-rsa/
    # cp -r /usr/share/easy-rsa/2.0/* /etc/openvpn/easy-rsa/
    # ll /etc/openvpn/easy-rsa/
    total 116
    -rwxr-xr-x. 1 root root   119 Apr 20 15:15 build-ca
    -rwxr-xr-x. 1 root root   352 Apr 20 15:15 build-dh
    -rwxr-xr-x. 1 root root   188 Apr 20 15:15 build-inter
    -rwxr-xr-x. 1 root root   163 Apr 20 15:15 build-key
    -rwxr-xr-x. 1 root root   157 Apr 20 15:15 build-key-pass
    -rwxr-xr-x. 1 root root   249 Apr 20 15:15 build-key-pkcs12
    -rwxr-xr-x. 1 root root   268 Apr 20 15:15 build-key-server
    -rwxr-xr-x. 1 root root   213 Apr 20 15:15 build-req
    -rwxr-xr-x. 1 root root   158 Apr 20 15:15 build-req-pass
    -rwxr-xr-x. 1 root root   449 Apr 20 15:15 clean-all
    -rwxr-xr-x. 1 root root  1471 Apr 20 15:15 inherit-inter
    drwx------. 2 root root  4096 Apr 26 21:31 keys
    -rwxr-xr-x. 1 root root   302 Apr 20 15:15 list-crl
    -rw-r--r--. 1 root root  7791 Apr 20 15:15 openssl-0.9.6.cnf
    -rw-r--r--. 1 root root  8348 Apr 20 15:15 openssl-0.9.8.cnf
    -rw-r--r--. 1 root root  8245 Apr 20 15:15 openssl-1.0.0.cnf
    -rwxr-xr-x. 1 root root 12966 Apr 20 15:15 pkitool
    -rwxr-xr-x. 1 root root   928 Apr 20 15:15 revoke-full
    -rwxr-xr-x. 1 root root   178 Apr 20 15:15 sign-req
    -rw-r--r--. 1 root root  2042 Apr 20 17:01 vars
    -rwxr-xr-x. 1 root root   740 Apr 20 15:15 whichopensslcnf
```
在开始制作CA证书之前，我们还需要编辑vars文件，修改如下相关选项内容即可。如下：

    # vim /etc/openvpn/easy-rsa/vars 
    export KEY_COUNTRY=”cn”
    export KEY_PROVINCE=”BJ”
    export KEY_CITY=”Chaoyang”
    export KEY_ORG=”user”
    export KEY_EMAIL=”user@user.com”
    export KEY_OU=”user”
    export KEY_NAME=”user”

vars文件主要用于设置证书的相关组织信息，引号部分的内容可以根据自己的实际情况自行修改。

然后使用source vars命令使其生效。

注意：执行clean-all命令会删除，当前目录下keys文件夹里证书等文件。

    # source vars.
    # ./clean-all

现在开始正式制作CA证书，使用如下命令：
```
    # ./build-ca
    Generating a 2048 bit RSA private key
    ............................................................................................................+++
    ........................................+++
    writing new private key to 'ca.key'
    -----
    You are about to be asked to enter information that will be incorporated
    into your certificate request.
    What you are about to enter is what is called a Distinguished Name or a DN.
    There are quite a few fields but you can leave some blank
    For some fields there will be a default value,
    If you enter '.', the field will be left blank.
    -----
    Country Name (2 letter code) [CN]:
    State or Province Name (full name) [BJ]:
    Locality Name (eg, city) [TZ]:
    Organization Name (eg, company) [CTG]:
    Organizational Unit Name (eg, section) [openvpn]:
    Common Name (eg, your name or your server's hostname) [CTG CA]:
    Name [openvpn]:
    Email Address [admin@admin.com]:
```


一路按回车键即可。制作完成后，我们可以查看keys目录。

    # ll /etc/openvpn/easy-rsa/keys/
    total 32
    -rw-r--r--. 1 root root 1639 Apr 27 13:06 ca.crt
    -rw-------. 1 root root 1704 Apr 27 13:06 ca.key
    -rw-r--r--. 1 root root  341 Apr 26 21:31 index.txt
    -rw-r--r--. 1 root root   21 Apr 25 23:16 index.txt.attr
    -rw-r--r--. 1 root root   21 Apr 25 23:16 index.txt.attr.old
    -rw-r--r--. 1 root root 2131 Apr 25 23:16 index.txt.old
    -rw-r--r--. 1 root root3 Apr 25 23:16 serial
    -rw-r--r--. 1 root root3 Apr 25 23:16 serial.old

我们可以看到已经生成了ca.crt和ca.key两个文件，其中ca.crt就是我们所说的CA证书。至此，CA证书制作完毕。
现在把该CA证书的ca.crt文件复制到openvpn的启动目录/etc/openvpn下：

    # cp /etc/openvpn/easy-rsa/keys/ca.crt /etc/openvpn
    # ll /etc/openvpn/
    total 16268
    -rw-r--r--. 1 root root 1639 Apr 20 17:02 ca.crt
    drwxr-xr-x. 3 root root 4096 Apr 27 13:00 easy-rsa

##### 3.2 制作Server端证书 #####
CA证书制作完成后，我们现在开始制作Server端证书。如下：

 ```   
	# ./build-key-server vpnserver
    Generating a 2048 bit RSA private key
    ........+++
    ........................................................................+++
    writing new private key to 'vpnserver.key'
    -----
    You are about to be asked to enter information that will be incorporated
    into your certificate request.
    What you are about to enter is what is called a Distinguished Name or a DN.
    There are quite a few fields but you can leave some blank
    For some fields there will be a default value,
    If you enter '.', the field will be left blank.
    -----
    Country Name (2 letter code) [CN]:
    State or Province Name (full name) [BJ]:
    Locality Name (eg, city) [TZ]:
    Organization Name (eg, company) [CTG]:
    Organizational Unit Name (eg, section) [openvpn]:
    Common Name (eg, your name or your server's hostname) [vpnserver]:
    Name [openvpn]:
    Email Address [admin@admin.com]:
    
    Please enter the following 'extra' attributes
    to be sent with your certificate request
    A challenge password []:
    An optional company name []:
    Using configuration from /etc/openvpn/easy-rsa/openssl-1.0.0.cnf
    Check that the request matches the signature
    Signature ok
    The Subject's Distinguished Name is as follows
    countryName   :PRINTABLE:'CN'
    stateOrProvinceName   :PRINTABLE:'BJ'
    localityName  :PRINTABLE:'TZ'
    organizationName  :PRINTABLE:'CTG'
    organizationalUnitName:PRINTABLE:'openvpn'
    commonName:PRINTABLE:'vpnserver'
    name  :PRINTABLE:'openvpn'
    emailAddress  :IA5STRING:'admin@admin.com'
    Certificate is to be certified until Apr 25 05:10:49 2026 GMT (3650 days)
    Sign the certificate? [y/n]:y
    
    
    1 out of 1 certificate requests certified, commit? [y/n]y
    Write out database with 1 new entries
    Data Base Updated
```    
一路执行并点击两次“y”即可，查看生成的Server端证书：

    # ll /etc/openvpn/easy-rsa/keys/
    total 56
    -rw-r--r--. 1 root root 1639 Apr 27 13:06 ca.crt
    -rw-------. 1 root root 1704 Apr 27 13:06 ca.key
    -rw-r--r--. 1 root root  458 Apr 27 13:10 index.txt
    -rw-r--r--. 1 root root 5346 Apr 27 13:10 vpnserver.crt
    -rw-r--r--. 1 root root 1058 Apr 27 13:10 vpnserver.csr
    -rw-------. 1 root root 1704 Apr 27 13:10 vpnserver.key

可以看到已经生成了vpnserver.crt、vpnserver.key和vpnserver.csr三个文件。其中vpnserver.crt和vpnserver.key两个文件是我们要使用的。

现在再为服务器生成加密交换时的Diffie-Hellman文件
    
    # ./build-dh 
    Generating DH parameters, 2048 bit long safe prime, generator 2
    This is going to take a long time
    ..........+..........................................................................................................................................................................+.....................................................+.......................................................................+.....................................................................................................................+.................................+....................................+...........................................................................+......................................................................................................................................................+...............................................................................................................+.....................+..................................................+......................................................................................................................................................................................................+.......................................+............................+.....................................................................................................................................+.........................................................................................+.........................................................................................................................................................................................+....................................................................................................................+.....................................+.........................+....................+.................................++*++*
    [root@centos6 easy-rsa]# ll keys/
    total 60
    -rw-r--r--. 1 root root 1639 Apr 27 13:06 ca.crt
    -rw-------. 1 root root 1704 Apr 27 13:06 ca.key
    -rw-r--r--. 1 root root  424 Apr 27 13:14 dh2048.pem
    -rw-r--r--. 1 root root  458 Apr 27 13:10 index.txt
    -rw-r--r--. 1 root root3 Apr 27 13:10 serial
    -rw-r--r--. 1 root root 5346 Apr 27 13:10 vpnserver.crt
    -rw-r--r--. 1 root root 1058 Apr 27 13:10 vpnserver.csr
    -rw-------. 1 root root 1704 Apr 27 13:10 vpnserver.key
    [root@centos6 easy-rsa]# 
    
已经生成了dh文件dh2048.pem。
把vpnserver.crt、vpnserver.key、dh2048.pem复制到/etc/openvpn/目录下

	# cd /etc/openvpn/easy-rsa    
	# cp keys/vpnserver.crt keys/vpnserver.key keys/dh2048.pem /etc/openvpn/
    # ll /etc/openvpn/
    total 16492
    -rw-r--r--. 1 root root 1639 Apr 20 17:02 ca.crt
    -rw-r--r--. 1 root root  424 Apr 20 17:07 dh2048.pem
    drwxr-xr-x. 3 root root 4096 Apr 27 13:00 easy-rsa
    -rw-r--r--. 1 root root 5342 Apr 20 17:07 openvpn.crt
    -rw-------. 1 root root 1704 Apr 20 17:07 openvpn.key


至此，Server端证书就制作完毕。

##### 3.3 制作Client端证书 #####

Server端证书制作完成后，我们现在开始制作Client端证书。
新建user1的证书


    # cd /etc/openvpn/easy-rsa 
    # ./build-key user1
    Generating a 2048 bit RSA private key
    .........+++
    ......................................+++
    writing new private key to 'user1.key'
    -----
    You are about to be asked to enter information that will be incorporated
    into your certificate request.
    What you are about to enter is what is called a Distinguished Name or a DN.
    There are quite a few fields but you can leave some blank
    For some fields there will be a default value,
    If you enter '.', the field will be left blank.
    -----
    Country Name (2 letter code) [CN]:
    State or Province Name (full name) [BJ]:
    Locality Name (eg, city) [TZ]:
    Organization Name (eg, company) [CTG]:
    Organizational Unit Name (eg, section) [openvpn]:
    Common Name (eg, your name or your server's hostname) [user1]:
    Name [openvpn]:
    Email Address [admin@admin.com]:
    
    Please enter the following 'extra' attributes
    to be sent with your certificate request
    A challenge password []:
    An optional company name []:
    Using configuration from /etc/openvpn/easy-rsa/openssl-1.0.0.cnf
    Check that the request matches the signature
    Signature ok
    The Subject's Distinguished Name is as follows
    countryName   :PRINTABLE:'CN'
    stateOrProvinceName   :PRINTABLE:'BJ'
    localityName  :PRINTABLE:'TZ'
    organizationName  :PRINTABLE:'CTG'
    organizationalUnitName:PRINTABLE:'openvpn'
    commonName:PRINTABLE:'user1'
    name  :PRINTABLE:'openvpn'
    emailAddress  :IA5STRING:'admin@admin.com'
    Certificate is to be certified until Apr 25 05:19:17 2026 GMT (3650 days)
    Sign the certificate? [y/n]:y
    
    
    1 out of 1 certificate requests certified, commit? [y/n]y
    Write out database with 1 new entries
    Data Base Updated
    
    [root@centos6 easy-rsa]# ll keys/
    total 84
    -rw-r--r--. 1 root root 1639 Apr 27 13:06 ca.crt
    -rw-------. 1 root root 1704 Apr 27 13:06 ca.key
    -rw-r--r--. 1 root root  424 Apr 27 13:14 dh2048.pem
    -rw-r--r--. 1 root root  571 Apr 27 13:19 index.txt
    -rw-r--r--. 1 root root3 Apr 27 13:19 serial
    -rw-r--r--. 1 root root 5216 Apr 27 13:19 user1.crt
    -rw-r--r--. 1 root root 1050 Apr 27 13:19 user1.csr
    -rw-------. 1 root root 1704 Apr 27 13:19 user1.key
    -rw-r--r--. 1 root root 5346 Apr 27 13:10 vpnserver.crt
    -rw-r--r--. 1 root root 1058 Apr 27 13:10 vpnserver.csr
    -rw-------. 1 root root 1704 Apr 27 13:10 vpnserver.key
    [root@centos6 easy-rsa]# 

已经生成了user1.csr、user1.crt和user1.key这个三个文件。user1.crt和user1.key两个文件是我们要使用的。
至此，Client端证书就制作完毕。

    
如果你想快速生成用户证书不需要手工交互的话，可以使用如下命令，例如生成user2
    
    # ./build-key --batch user2
    Generating a 2048 bit RSA private key
    ...................................................+++
    .......................................+++
    writing new private key to 'user2.key'
    -----
    Using configuration from /etc/openvpn/easy-rsa/openssl-1.0.0.cnf
    Check that the request matches the signature
    Signature ok
    The Subject's Distinguished Name is as follows
    countryName   :PRINTABLE:'CN'
    stateOrProvinceName   :PRINTABLE:'BJ'
    localityName  :PRINTABLE:'TZ'
    organizationName  :PRINTABLE:'CTG'
    organizationalUnitName:PRINTABLE:'openvpn'
    commonName:PRINTABLE:'user2'
    name  :PRINTABLE:'openvpn'
    emailAddress  :IA5STRING:'admin@admin.com'
    Certificate is to be certified until Apr 25 05:21:01 2026 GMT (3650 days)
    failed to update database
    TXT_DB error number 2
    You have new mail in /var/spool/mail/root
    
### 四、配置Server端 ###
所有证书制作完毕后，我们现在开始配置Server端。Server端的配置文件，我们可以从openvpn自带的模版中进行复制。

    # cp /usr/share/doc/openvpn-2.3.10/sample/sample-config-files/server.conf /etc/openvpn/server.conf.bak
    # cd /etc/openvpn/
    # ll
    total 16720
    -rw-r--r--. 1 root root 1639 Apr 20 17:02 ca.crt
    -rw-r--r--. 1 root root  424 Apr 20 17:07 dh2048.pem
    drwxr-xr-x. 3 root root 4096 Apr 27 13:00 easy-rsa
    -rw-r--r--. 1 root root 5342 Apr 20 17:07 openvpn.crt
    -rw-------. 1 root root 1704 Apr 20 17:07 openvpn.key
    -rw-r--r--. 1 root root10441 Apr 20 17:20 server.conf.bak


我们通过grep修改server.conf.bak文件来生成server.conf文件

    # grep -vE "^#|^;|^$" server.conf.bak > server.conf
    # vim server.conf
    port 1194
    proto tcp		-->修改处
    dev tun		
    ca ca.crt
    cert vpnserver.crt	-->修改处
    key vpnserver.key	-->修改处
    dh dh2048.pem
    server 10.8.0.0 255.255.255.0
    ifconfig-pool-persist ipp.txt
    keepalive 10 120
    comp-lzo
    persist-key
    persist-tun
    status openvpn-status.log
    verb 3

与原模版文件相比，在此我修改几个地方。
第一、修改了openvpn运行时使用的协议，由原来的UDP协议修改为TCP协议。生成环境建议使用TCP协议。
第二、修改了openvpn服务器的相关证书，由原来的server.csr、server.key修改为vpnserver.crt、vpnserver.key。
注意：上述server.conf文件中vpnserver.crt、vpnserver.key、dh2048.pem要与/etc/openvpn/目录下的相关文件一一对应。
同时，如果上述文件如果没有存放在/etc/openvpn/目录下，在server.conf文件中，我们要填写该文件的绝对路径。

配置文件修改完毕后，我们现在来启动openvpn，使用如下命令：

    # service openvpn start
    Starting openvpn:  [  OK  ]
    # ss -tnlp |grep 1194
    LISTEN 0  1 *:1194 *:*  users:(("openvpn",1765,5))
    # 

可以的看出openvpn已经在此启动，使用的TCP协议的1194端口。

### 五、配置Client端 ###
Server端配置并启动后，我们现在来配置Client端。我们主要在Windows OS上。

##### 5.1 在Windows OS上 #####
下载安装“openvpn-2.1.1-gui-1.0.3-install-cn-64bit”，地址为:	https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/vpntech/openvpn-2.1.1-gui-1.0.3-install-cn-64bit.zip

在windows的Client段，安装完毕Openvpn后，程序安装路径
缺省目录是：C:\Program Files (x86)\OpenVPN\
在C:\Program Files (x86)\OpenVPN\config下新建一个文件夹存放用户的配置证书

![](http://www.178linux.com/ueditor/php/upload/image/20160421/1461210082120817.png)



##### 5.2 在OpenVPN server上 #####
我们都需要把Client证书、CA证书以及Client配置文件下载到Client端。
Client证书我们主要使用crt和key结尾的两个文件，而CA证书我们主要使用crt结尾的文件。在Server端新建一个用户user1存放证书的目录，并将需要的证书文件存放到此目录。

    # mkdir /root/user1/ -pv
    # cp /usr/share/doc/openvpn-2.3.10/sample/sample-config-files/client.conf /root/user1/client.ovpn
    # cd /etc/openvpn/easy-rsa/keys
    # cp user1.crt user1.key /root/user1/
    # ll /root/user1
    total 16
    -rw-r--r--. 1 root root 3441 Apr 27 13:31 client.ovpn
    -rw-r--r--. 1 root root 5216 Apr 27 13:32 user1.crt
    -rw-------. 1 root root 1704 Apr 27 13:32 user1.key

存放完毕后，通过sz将这几个文件下载到存放user1配置文件的目录

    # cd /root/user1
    # sz *

![](http://www.178linux.com/ueditor/php/upload/image/20160421/1461210088147172.png)

##### 5.3 配置client段配置文件 #####
下载完毕后，然后编辑client.ovpn，如下

    client
    dev tun
    proto tcp
    remote openvpnserver.user.com 1194
    resolv-retry infinite
    nobind
    persist-key
    persist-tun
    ca ca.crt
    cert user1.crt
    key user1.key
    ns-cert-type server
    comp-lzo
    verb 3

![](http://www.178linux.com/ueditor/php/upload/image/20160421/1461210101102918.png)

Client配置文件client.ovpn，修改了几个地方：

第一、使用的协议，由原来的UDP修改为TCP，这个一定要和Server端保持一致。否则Client无法连接。
第二、remote地址，这个地址要修改为Server端的地址。
第三、Client证书名称，这个要和我们现在使用用户的Client证书名称保持一致。

现在我们来启动openvpn客户端连接Server，如下：
![](http://www.178linux.com/ueditor/php/upload/image/20160421/1461210105776969.png)

点击“连接服务”，会出现如下的弹窗：
![](http://www.178linux.com/ueditor/php/upload/image/20160421/1461210108292540.png)
如果配置都正确的话，会出现如下的提示：
![](http://www.178linux.com/ueditor/php/upload/image/20160421/1461210114175769.png)
通过上图，我们可以很明显的看到Client已经正确连接Server端，并且获得的IP地址是10.8.0.6。

到此为止，openvpn的配置完成，
