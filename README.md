# Execute multi-node cluster for ZooKeeper development

This small repo helps you to execute custom ZooKeeper version on
docker, by mounting your zookeeper local build to standard openjdk images.
The current implementation will extract and use the `zookeeper-assembly/target/*-bin.tar.gz` file from your local git
repository when starting the container.


## Using different cluster setups

The clusters are specified in compose files. You can customize them, these are the ones I created:
- `3_nodes_zk.yml`: three zookeeper nodes, using a single virtual network
- `3_nodes_2_networks_zk.yml`: three zookeeper nodes, using two virtual networks (created for testing [ZOOKEEPER-3188](https://issues.apache.org/jira/browse/ZOOKEEPER-3188))
- `4_nodes_2_networks_zk.yml`: four zookeeper nodes, using two virtual networks (created for testing [ZOOKEEPER-3188](https://issues.apache.org/jira/browse/ZOOKEEPER-3188))
- `3_nodes_digets_quorum_auth_zk.yml`: three zookeeper nodes, using a single virtual network and digest SASL authentication
- `3_nodes_zk_no_wildcard_addr.yml`: three zookeeper nodes, having proper hosts in the server configs (not using 0.0.0.0 anywhere)
- `3_nodes_zk_jdk_12.yml`: three zookeeper nodes on OpenJDK 12.0.2 (to reproduce issue in [ZOOKEEPER-3769](https://issues.apache.org/jira/browse/ZOOKEEPER-3769))
- `3_nodes_zk_dynamic_config.yml`: three zookeeper nodes using separate dynamic config file supported in 3.6.0+ (to reproduce issue in [ZOOKEEPER-3776](https://issues.apache.org/jira/browse/ZOOKEEPER-3776))
- `3_nodes_zk_mounted_data_folder.yml`: three zookeeper nodes storing all their config and data in a mounted volume

To simulate the case of changing a hostname of a server without using dynamic reconfig ([ZOOKEEPER-3814](https://issues.apache.org/jira/browse/ZOOKEEPER-3814)):
- start first `3_nodes_zk_mounted_data_folder.yml`, then stop it
- then start `3_nodes_zk_server_hostname_changed.yml`

Some ports are also exposed on localhost, so you can connect to your cluster. My port configs (for server X):
- REST api port: 808(X) (e.g. for server 1 use: http://localhost:8081/commands/leader)
- Client port: 218(X) (e.g. for server 3 use: localhost:2183)

## Starting the docker cluster:

```
# the docker containers will mount both the zookeeper source code folder
# and the folder of the docker helper scripts, we need to define these folders first
export ZOOKEEPER_GIT_REPO=~/git/zookeeper
export ZOOKEEPER_DOCKER_TEST_GIT_REPO=~/git/zookeeper-docker-test

# you always need to do a maven install to have the assembly tar.gz file updated!
cd $ZOOKEEPER_GIT_REPO
mvn clean install -DskipTests

cd $ZOOKEEPER_DOCKER_TEST_GIT_REPO
docker-compose --project-name zookeeper --file 3_nodes_zk.yml up

```

## Playing with the virtual networks / nodes
While the cluster is running, you can use the following commands on a different shell:
- list networks: `docker network ls`
- disconnect the 3rd container from network 1: `docker network disconnect zookeeper_net_1 zookeeper_zoo3_1`
- reconnect the same container later with the same IP: `docker network connect --ip 172.16.101.33 zookeeper_net_1 zookeeper_zoo3_1`
- restarting a single ZooKeeper server: `docker-compose --file 3_nodes_zk.yml --project-name zookeeper restart zoo2`
- stopping a single ZooKeeper server: `docker-compose --file 3_nodes_zk.yml --project-name zookeeper stop zoo3`
- starting a single ZooKeeper server: `docker-compose --file 3_nodes_zk.yml --project-name zookeeper start zoo3`
- use 4lw command 'stat' on the second ZK server (given it's ZK port is exposed on the port 2182 of the host machine): `echo "stat" | nc localhost 2182`

## Stopping the docker cluster:
- first press ctrl-C on the shell where the zookeeper cluster is running
- then remove the networks / leftovers: `docker-compose --file 3_nodes_zk.yml --project-name zookeeper down`


## Connecting to a running zookeeper node (e.g. to start a client)
```
# you can see the running containers:
docker ps

CONTAINER ID        IMAGE               COMMAND                  CREATED              STATUS              PORTS                                            NAMES
debdc72d864c        openjdk:8u222-jre   "/bin/bash /scripts/…"   About a minute ago   Up About a minute   0.0.0.0:2181->2181/tcp, 0.0.0.0:8081->8080/tcp   zookeeper_zoo1_1
f1702d83721c        openjdk:8u222-jre   "/bin/bash /scripts/…"   About a minute ago   Up About a minute   0.0.0.0:2183->2181/tcp, 0.0.0.0:8083->8080/tcp   zookeeper_zoo3_1
15dea744231d        openjdk:8u222-jre   "/bin/bash /scripts/…"   About a minute ago   Up About a minute   0.0.0.0:2182->2181/tcp, 0.0.0.0:8082->8080/tcp   zookeeper_zoo2_1


# connect to server 1:
docker exec -it zookeeper_zoo1_1 /bin/bash

root@zoo1:/# cd /zookeeper/bin/
root@zoo1:/zookeeper/bin# ./zkCli.sh

# or to start the zookeeper client on server 2 using a single command:
docker exec -it zookeeper_zoo1_1 /bin/bash /zookeeper/bin/zkCli.sh
```


## Connecting to a running zookeeper node with digest authentication 
Assuming you used `3_nodes_digest_quorum_auth.yml` to start your cluster, you can start a cli by:
```
docker exec -e CLIENT_JVMFLAGS="-Djava.security.auth.login.config=/scripts/conf/digest_jaas_client.conf" -it zookeeper_zoo1_1 /bin/bash /zookeeper/bin/zkCli.sh
```

## Logging

The containers will log with INFO threshold to the console and DEBUG logs will be produced into log files under the `logs` folder. You can change the log levels in the `start_zookeeper.sh` file.


## License

Good old Apache License 2.0