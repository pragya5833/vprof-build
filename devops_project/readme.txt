1) container: Nginx
2) container: apache tomcat
3) container: mysql server
4) container: rabbit mq
4) container : memcached

order:
mysql
memcached
mq
tomcat
nginx

on AWS:
1) SG for LB ingress rule for all conns
2) SG for tomcat ingress rule to connect with lb
3) SG for mq(5472),mysql(3306),memcache(11211) : self =True ingress rule to connect with each other and ingress rule to connect with app
4) key pair
5) userdata templates to install services on instances
6) instances-app,mysql,mq,cache
7) get private ip of all these to be updated in R53
mq: 172.31.40.228
sql: 172.31.35.249
cache: 172.31.32.36