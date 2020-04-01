#!/bin/bash

CUSTOM_ZOO_CFG=${CUSTOM_ZOO_CFG:-/scripts/conf/zoo.cfg}

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

cp $CUSTOM_ZOO_CFG /zookeeper/conf/zoo.cfg

DYNAMIC_SERVER_INFO_FILE=${DYNAMIC_SERVER_INFO_FILE:-/zookeeper/conf/zoo.cfg}
for server in $ZOO_SERVERS; do
    echo "$server" >> $DYNAMIC_SERVER_INFO_FILE
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

if [ "$DYNAMIC_SERVER_INFO_FILE" == "/zookeeper/conf/zoo.cfg" ]; then
    echo "========= dynamic config file: N/A ========="
else
    echo "========= dynamic config file: $DYNAMIC_SERVER_INFO_FILE ========="
    cat $DYNAMIC_SERVER_INFO_FILE
fi
echo "========= java version ========="
java -version
echo "==========================="

cd /zookeeper/bin
./zkServer.sh start-foreground 2>&1