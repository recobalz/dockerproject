通过docker-compose部署wordpress网站
```
docker-compose up -d
```
通过docker-compose.yml部署到docker swarm里
```
docker stack deploy --compose-file=docker-compose.yml wordpress
```
通过mytop镜像查看数据库状态
```
docker run --rm -it --network wordpress_default --link wordpress_db_1:db srcoder/mytop -h db -pwordpress -d wordpress
```
