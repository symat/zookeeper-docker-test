#!/bin/bash

mkdir /zookeeper
tar xzf /zookeeper_src/zookeeper-assembly/target/*-bin.tar.gz --directory /zookeeper --strip-components=1

export PATH=$PATH:/zookeeper/bin
export ZOOCFGDIR=/zookeeper/conf
ZOO_MY_ID=${ZOO_MY_ID:-1}
if [[ -z $ZOO_SERVERS ]]; then
  ZOO_SERVERS="server.1=localhost:2888:3888;2181"
fi

mkdir -p /datalog /data /conf
echo "$ZOO_MY_ID" > /data/myid

cp /scripts/conf/zoo.cfg /zookeeper/conf/
for server in $ZOO_SERVERS; do
    echo "$server" >> /zookeeper/conf/zoo.cfg
done

export ZOO_LOG_DIR=/scripts/logs/$ZOO_MY_ID
mkdir -p $ZOO_LOG_DIR
rm -f $ZOO_LOG_DIR/*.log
export ZOO_LOG4J_PROP="DEBUG,CONSOLE,ROLLINGFILE"
export SERVER_JVMFLAGS="$EXTRA_SERVER_JVM_FLAGS -Dzookeeper.log.threshold=DEBUG -Dzookeeper.console.threshold=INFO"

echo "========= /data/myid ========="
cat /data/myid
echo "========= /conf/zoo.cfg ========="
cat /zookeeper/conf/zoo.cfg
echo "========= java version ========="
java -version
echo "==========================="

cd /zookeeper/bin
./zkServer.sh start-foreground 2>&1