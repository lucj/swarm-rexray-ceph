## Purpose

Setup a Docker swarm cluster using REX-Ray and Ceph for the orchestration of the storage layer

## Prerequisites

1. Get Ansible from [http://docs.ansible.com/ansible/latest/intro_installation.html](http://docs.ansible.com/ansible/latest/intro_installation.html)

2. Setup the infrastructure 

In this first version, I've only tested with DigitalOcean droplets:
* one manager used to deploy a Ceph cluster
* three nodes participating to the Ceph cluster and running Docker swarm

> On each of the 3 nodes, an additonal DigitalOcean volume has been added. The 3 volumes will be used by Ceph and available by default as */dev/sda* drive.

```
$ terraform plan
var.do_key_id
  Enter a value: xxxxxx

var.do_token
  Enter a value: yyyyyyyyyyyyyyyyyyyyyyyyy

Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.
...
Plan: 7 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.
````

Once the *plan* step is ok, let's *apply* the configuration and deploy the infrastructure

```
$ terraform apply
var.do_key_id
  Enter a value: xxxxxx

var.do_token
  Enter a value: yyyyyyyyyyyyyyyyyyyyyyyyy

Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.
...
Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

Outputs:

adm_ip_addresses = adm: 178.62.7.17
nodes_ip_addresses = [
    46.101.93.150,
    138.68.136.192,
    138.68.128.157
]
nodes_name = [
    node1,
    node2,
    node3
]
```

3. Modify your local /etc/hosts to define the machine with IPs obtained:
* adm
* node1
* node2
* node3

```
...
178.62.7.17    adm
46.101.93.150  node1
138.68.136.192 node2
138.68.128.157 node3
```

## Test machines

Make sure the machine can be accessed

```
$ ansible -i inventory.ini -u root -m ping all
node3 | SUCCESS => {
    "changed": false,
    "failed": false,
    "ping": "pong"
}
adm | SUCCESS => {
    "changed": false,
    "failed": false,
    "ping": "pong"
}
node1 | SUCCESS => {
    "changed": false,
    "failed": false,
    "ping": "pong"
}
node2 | SUCCESS => {
    "changed": false,
    "failed": false,
    "ping": "pong"
}
```

## Deploy

The cluster can be deployed with the following command

```
$ ansible-playbook -i inventory.ini -u root main.yml
```

## Results

A 3 nodes swarm cluster with REX-Ray using a Ceph cluster

## Usage

From one of the cluster's nodes, create a REX-Ray volume named data

```
root@node1:~# rexray volume create data --size=10
ID        Name  Status     Size
rbd.data  data  available  10
```

This volume is seen as a Docker volume as the following commands show

```
root@node1:~# docker volume ls
DRIVER              VOLUME NAME
rexray              data
```

The *inspect* command provides detailed information on the volume, such as the type.

```
$ docker volume inspect data
[
    {
        "CreatedAt": "0001-01-01T00:00:00Z",
        "Driver": "rexray",
        "Labels": null,
        "Mountpoint": "/",
        "Name": "data",
        "Options": {},
        "Scope": "global",
        "Status": {
            "name": "data",
            "type": "rbd"
        }
    }
]
```

This volume is now available from any host of the Ceph cluster

```
root@node2:~# docker volume ls
DRIVER              VOLUME NAME
rexray              data

root@node3:~# docker volume ls
DRIVER              VOLUME NAME
rexray              data
```

Let's now create a Docker service using this volume. The following command creates a service based on *mongodb* and mount the volume.

```
$ docker service create \
  --replicas 1 \
  --name mongo \
  --mount type=volume,src=data,target=/data/db,volume-driver=rexray \
  mongo:3.4
```

In this example, we can see that the replica of the service was scheduled on *node3*

```
root@node1:~# docker service ps mongo
ID                  NAME                IMAGE               NODE                DESIRED STATE       CURRENT STATE            ERROR               PORTS
y0ebuweh8vwp        mongo.1             mongo:3.4           node3               Running             Running 13 seconds ago
```

The service's container has correctly started and the database is waiting for connection:

```
$ root@node1:~# docker service logs mongo
mongo.1.y0ebuweh8vwp@node3    | 2017-12-01T15:48:33.087+0000 I CONTROL  [initandlisten] MongoDB starting : pid=1 port=27017 dbpath=/data/db 64-bit host=deac61a5c833
mongo.1.y0ebuweh8vwp@node3    | 2017-12-01T15:48:33.088+0000 I CONTROL  [initandlisten] db version v3.4.10
mongo.1.y0ebuweh8vwp@node3    | 2017-12-01T15:48:33.088+0000 I CONTROL  [initandlisten] git version: 078f28920cb24de0dd479b5ea6c66c644f6326e9
mongo.1.y0ebuweh8vwp@node3    | 2017-12-01T15:48:33.088+0000 I CONTROL  [initandlisten] OpenSSL version: OpenSSL 1.0.1t  3 May 2016
mongo.1.y0ebuweh8vwp@node3    | 2017-12-01T15:48:33.088+0000 I CONTROL  [initandlisten] allocator: tcmalloc
mongo.1.y0ebuweh8vwp@node3    | 2017-12-01T15:48:33.088+0000 I CONTROL  [initandlisten] modules: none
mongo.1.y0ebuweh8vwp@node3    | 2017-12-01T15:48:33.088+0000 I CONTROL  [initandlisten] build environment:
mongo.1.y0ebuweh8vwp@node3    | 2017-12-01T15:48:33.088+0000 I CONTROL  [initandlisten]     distmod: debian81
mongo.1.y0ebuweh8vwp@node3    | 2017-12-01T15:48:33.088+0000 I CONTROL  [initandlisten]     distarch: x86_64
mongo.1.y0ebuweh8vwp@node3    | 2017-12-01T15:48:33.088+0000 I CONTROL  [initandlisten]     target_arch: x86_64
mongo.1.y0ebuweh8vwp@node3    | 2017-12-01T15:48:33.088+0000 I CONTROL  [initandlisten] options: {}
mongo.1.y0ebuweh8vwp@node3    | 2017-12-01T15:48:33.094+0000 I STORAGE  [initandlisten]
mongo.1.y0ebuweh8vwp@node3    | 2017-12-01T15:48:33.094+0000 I STORAGE  [initandlisten] ** WARNING: Using the XFS filesystem is strongly recommended with the WiredTiger storage engine
mongo.1.y0ebuweh8vwp@node3    | 2017-12-01T15:48:33.095+0000 I STORAGE  [initandlisten] **          See http://dochub.mongodb.org/core/prodnotes-filesystem
mongo.1.y0ebuweh8vwp@node3    | 2017-12-01T15:48:33.096+0000 I STORAGE  [initandlisten] wiredtiger_open config: create,cache_size=256M,session_max=20000,eviction=(threads_min=4,threads_max=4),config_base=false,statistics=(fast),log=(enabled=true,archive=true,path=journal,compressor=snappy),file_manager=(close_idle_time=100000),checkpoint=(wait=60,log_size=2GB),statistics_log=(wait=0),
mongo.1.y0ebuweh8vwp@node3    | 2017-12-01T15:48:33.478+0000 I CONTROL  [initandlisten]
mongo.1.y0ebuweh8vwp@node3    | 2017-12-01T15:48:33.478+0000 I CONTROL  [initandlisten] ** WARNING: Access control is not enabled for the database.
mongo.1.y0ebuweh8vwp@node3    | 2017-12-01T15:48:33.478+0000 I CONTROL  [initandlisten] **          Read and write access to data and configuration is unrestricted.
mongo.1.y0ebuweh8vwp@node3    | 2017-12-01T15:48:33.478+0000 I CONTROL  [initandlisten]
mongo.1.y0ebuweh8vwp@node3    | 2017-12-01T15:48:33.479+0000 I CONTROL  [initandlisten]
mongo.1.y0ebuweh8vwp@node3    | 2017-12-01T15:48:33.479+0000 I CONTROL  [initandlisten] ** WARNING: /sys/kernel/mm/transparent_hugepage/enabled is 'always'.
mongo.1.y0ebuweh8vwp@node3    | 2017-12-01T15:48:33.479+0000 I CONTROL  [initandlisten] **        We suggest setting it to 'never'
mongo.1.y0ebuweh8vwp@node3    | 2017-12-01T15:48:33.479+0000 I CONTROL  [initandlisten]
mongo.1.y0ebuweh8vwp@node3    | 2017-12-01T15:48:33.479+0000 I CONTROL  [initandlisten] ** WARNING: /sys/kernel/mm/transparent_hugepage/defrag is 'always'.
mongo.1.y0ebuweh8vwp@node3    | 2017-12-01T15:48:33.479+0000 I CONTROL  [initandlisten] **        We suggest setting it to 'never'
mongo.1.y0ebuweh8vwp@node3    | 2017-12-01T15:48:33.479+0000 I CONTROL  [initandlisten]
mongo.1.y0ebuweh8vwp@node3    | 2017-12-01T15:48:33.581+0000 I FTDC     [initandlisten] Initializing full-time diagnostic data capture with directory '/data/db/diagnostic.data'
mongo.1.y0ebuweh8vwp@node3    | 2017-12-01T15:48:33.712+0000 I INDEX    [initandlisten] build index on: admin.system.version properties: { v: 2, key: { version: 1 }, name: "incompatible_with_version_32", ns: "admin.system.version" }
mongo.1.y0ebuweh8vwp@node3    | 2017-12-01T15:48:33.712+0000 I INDEX    [initandlisten]      building index using bulk method; build may temporarily use up to 500 megabytes of RAM
mongo.1.y0ebuweh8vwp@node3    | 2017-12-01T15:48:33.713+0000 I INDEX    [initandlisten] build index done.  scanned 0 total records. 0 secs
mongo.1.y0ebuweh8vwp@node3    | 2017-12-01T15:48:33.714+0000 I COMMAND  [initandlisten] setting featureCompatibilityVersion to 3.4
mongo.1.y0ebuweh8vwp@node3    | 2017-12-01T15:48:33.714+0000 I NETWORK  [thread1] waiting for connections on port 27017
```

From the running container, we create a new database called *rexray* and a new record within a collection:

```
$ docker exec -ti $(docker ps -q --filter "label=com.docker.swarm.service.name=mongo") bash
/# mongo
> use rexray
switched to db rexray
> db.ceph.insert({status: "ok"})
WriteResult({ "nInserted" : 1 })
```

We then simulate an outage of *node3* (the node running the container of our service) by stopping the Docker daemon

```
$ root@node3:~# systemctl stop docker
Warning: Stopping docker.service, but it can still be activated by:
  docker.socket
```

We can wait a little bit and see the service's container has been re-scheduled on another node (*node1* in this example)

```
root@node1:~# docker service ls
ID                  NAME                MODE                REPLICAS            IMAGE               PORTS
glwnh8r5gkv0        mongo               replicated          1/1                 mongo:3.4
```

If we have a closer look, we can see there was on error when the service was rescheduled on *node2* prior to be scheduled on *node1*

```
root@node1:~# docker service ps mongo
ID                  NAME                IMAGE               NODE                DESIRED STATE       CURRENT STATE            ERROR                              PORTS
mnsmsiwwdkeg        mongo.1             mongo:3.4           node1               Running             Running 30 seconds ago
8z52pwhptqti         \_ mongo.1         mongo:3.4           node2               Shutdown            Rejected 3 minutes ago   "VolumeDriver.Mount: Controlle…"
y0ebuweh8vwp         \_ mongo.1         mongo:3.4           node3               Shutdown            Running 4 minutes ago
```

The whole error is: __"VolumeDriver.Mount: ControllerPublishVolume failed: 0: ControllerPublishVolume failed: 0: rpc error: code = Unknown desc = volume in wrong state for attach"___

Not sure the reason of this failure though...

Now that the service has correctly be deployed on *node1*, we can check the database:

```
$ root@node1:~# docker exec -ti $(docker ps -q --filter "label=com.docker.swarm.service.name=mongo") bash
root@768fa921dc77:/# mongo
> use rexray
switched to db rexray
> db.ceph.find()
{ "_id" : ObjectId("5a217b912e3087de1588a147"), "status" : "ok" }
```

We can see the volume created previously has been attached to the new container.

## Status

WIP: This project is very early stage, a lot of things to be done...

- [ ] setup examples
- [ ] tests... a lot
- [ ] add terraform file for AWS
- [ ] ... you name it

Any feedback is welcome

