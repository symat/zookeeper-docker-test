# Execute multi-node cluster for ZooKeeper development

This small repo helps you to execute custom ZooKeeper version on
docker, by mounting your zookeeper local build to standard openjdk images.
The current implementation will extract and use the `zookeeper-assembly/target/*-bin.tar.gz` file from your local git
repository when starting the container.


## using different cluster setups

The clusters are specified in compose files. You can customize them, these are the ones I created:
- `3_nodes_zk.yml`: three zookeeper nodes, using a single virtual network
- `3_nodes_2_networks_zk.yml`: three zookeeper nodes, using two virtual networks (created for testing [ZOOKEEPER-3188](https://issues.apache.org/jira/browse/ZOOKEEPER-3188))
- `4_nodes_2_networks_zk.yml`: four zookeeper nodes, using two virtual networks (created for testing [ZOOKEEPER-3188](https://issues.apache.org/jira/browse/ZOOKEEPER-3188))

Some ports are also exposed on localhost, so you can connect to your cluster. My port configs (for server X):
- REST api port: 808<X> (e.g. for server 1 use: http://localhost:8081/commands/leader)
- Client port: 218<X> (e.g. for server 3 use: localhost:2183)

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
docker-compose --file 3_nodes_zk.yml --project-name zookeeper up

```

## Playing with the virtual networks
- list networks: `docker network ls`
- disconnect a container from network: `docker network disconnect zookeeper_net_1 zookeeper_zoo3_1`


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


# connect to node 1:
docker exec -it zookeeper_zoo1_1 /bin/bash

root@zoo1:/# cd /zookeeper/bin/
root@zoo1:/zookeeper/bin# ./zkCli.sh
```

