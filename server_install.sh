#!/bin/bash

# dd if=/dev/zero of=/swapfile bs=1M count=2560
# chown root:root  /swapfile
# chmod 600 /swapfile
# mkswap /swapfile
# swapon /swapfile
# echo "/swapfile   swap    swap    sw  0   0" >> /etc/fstab
# echo "vm.swappiness = 100" >> /etc/sysctl.conf
# echo "vm.vfs_cache_pressure = 50" >> /etc/sysctl.conf
# sysctl -p
apt-get update
sudo apt-get install -y mc maven git openjdk-8-jdk
mkdir /var/log/zookeeper
mkdir /home/ubuntu/zookeeper
cd /home/ubuntu/zookeeper && wget http://apache.cp.if.ua/zookeeper/zookeeper-3.4.11/zookeeper-3.4.11.tar.gz && tar -xzvf zookeeper-3.4.11.tar.gz && cd zookeeper-3.4.11/ && cp conf/zoo_sample.cfg conf/zoo.cfg && echo "dataLogDir=/var/log/zookeeper" >> conf/zoo.cfg && bin/zkServer.sh start &
mkdir /home/ubuntu/exhibitor
echo """zookeeper-data-directory=/tmp/zookeeper
zookeeper-install-directory=/home/ubuntu/zookeeper/zookeeper-3.4.11
client-port=2181
connect-port=2888
election-port=3888
auto-manage-instances=1
auto-manage-instances-settling-period-ms=18000
zookeeper-log-directory=/var/log/zookeeper
""" >> /home/ubuntu/exhibitor/exhibitor.properties

cd /home/ubuntu/exhibitor && wget https://raw.github.com/Netflix/exhibitor/master/exhibitor-standalone/src/main/resources/buildscripts/standalone/maven/pom.xml && mvn clean package
SERVERHOSTNAME=`/usr/bin/curl http://169.254.169.254/latest/meta-data/local-ipv4` && java -jar target/exhibitor-1.6.0.jar -c s3 --defaultconfig /home/ubuntu/exhibitor/exhibitor.properties --s3region "us-east-1" --s3config my-zookeper-prop-bucket:exhibitor --hostname $SERVERHOSTNAME &
#java -jar target/exhibitor-1.6.0.jar -c file --defaultconfig  /home/ubuntu/exhibitor/exhibitor.properties --fsconfigdir /vagrant_data/ --fsconfigname exhibitor-auto.prop --hostname $1 &
#java -jar target/exhibitor-1.6.0.jar -c s3 --defaultconfig ex.prop --s3credentials ex.cred --s3region "us-east-1" --s3config puppet_bucket_test:exhibitor &
#java -jar target/exhibitor-1.6.0.jar -c s3 --defaultconfig ex.prop --s3region "us-east-1" --s3config my-zookeper-prop-bucket:exhibitor --hostname $SERVERHOSTNAME
