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

ZOO_CFG_PATH=/zookeeper/conf/zoo.cfg

if [ "x$CUSTOM_DATA_FOLDER" = "x" ] ; then
  mkdir -p /datalog /data
else
  mkdir -p $CUSTOM_DATA_FOLDER/datalog
  mkdir -p $CUSTOM_DATA_FOLDER/data
  rm -f $CUSTOM_DATA_FOLDER/zoo.cfg
  ZOO_CFG_PATH=$CUSTOM_DATA_FOLDER/zoo.cfg
  rm -fR /datalog
  rm -fR /data
  ln -s $CUSTOM_DATA_FOLDER/datalog /datalog
  ln -s $CUSTOM_DATA_FOLDER/data /data
fi

mkdir -p  /conf
echo "$ZOO_MY_ID" > /data/myid

cp $CUSTOM_ZOO_CFG $ZOO_CFG_PATH

DYNAMIC_SERVER_INFO_FILE=${DYNAMIC_SERVER_INFO_FILE:-$ZOO_CFG_PATH}
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
echo "========= zoo.cfg: $ZOO_CFG_PATH ========="
cat $ZOO_CFG_PATH

if [ "$DYNAMIC_SERVER_INFO_FILE" == "$ZOO_CFG_PATH" ]; then
    echo "========= dynamic config file: N/A ========="
else
    echo "========= dynamic config file: $DYNAMIC_SERVER_INFO_FILE ========="
    cat $DYNAMIC_SERVER_INFO_FILE
fi
echo "========= java version ========="
java -version
echo "==========================="

cd /zookeeper/bin
./zkServer.sh start-foreground $ZOO_CFG_PATH 2>&1