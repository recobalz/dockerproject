1 容器的运行命令
```
docker run --name='gitlab-ce' -d \
       -p 10022:22 -p 80:80 \
       --restart always \
       --volume /data/gitlab/config:/etc/gitlab \
       --volume /data/gitlab/logs:/var/log/gitlab \
       --volume /data/gitlab/data:/var/opt/gitlab \
       gitlab/gitlab-ce
```

2 配置gitlab服务器的访问地址;需要配置gitlab.rb（宿主机上的路径为：/data/gitlab/config/gitlab.rb）配置文件里面的参数。

```
# 配置http协议所使用的访问地址
external_url 'http://10.200.0.100'

# 配置ssh协议所使用的访问地址和端口
gitlab_rails['gitlab_ssh_host'] = '10.200.0.100'
gitlab_rails['gitlab_shell_ssh_port'] = 10022
```

3 配置邮件发送功能;也是修改gitlab.rb配置文件来完成。
```
# 这里以新浪的邮箱为例配置smtp服务器
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.sina.com"
gitlab_rails['smtp_port'] = 25
gitlab_rails['smtp_user_name'] = "name4mail"
gitlab_rails['smtp_password'] = "passwd4mail"
gitlab_rails['smtp_domain'] = "sina.com"
gitlab_rails['smtp_authentication'] = :login
gitlab_rails['smtp_enable_starttls_auto'] = true

# 还有个需要注意的地方是指定发送邮件所用的邮箱，这个要和上面配置的邮箱一致
gitlab_rails['gitlab_email_from'] = 'name4mail@sina.com'
```
注意，每次修改gitlab.rb配置文件之后，或者在容器里执行gitlab-ctl reconfigure命令，或者重启容器以让新配置生效。

其他

1) 如果想要支持https的话，还需要配置一下nginx； 
2) 如果不想在登录界面出现用户自注册的输入界面的话，可以在Admin Area->Settings->Sign-in Restrictions里将Sign-up enabled选项去掉； 
3) 国内的网络大家都懂的，gitlab使用的Gravatar头像时常显示不出来，如果不想用这功能，可以在Admin Area->Settings->Account and Limit Settings里将Gravatar enabled选项去掉； 
