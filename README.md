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
  Enter a value: 867702

var.do_token
  Enter a value: fdefc3e48abeb8bb317f044af3bceedce4a73ece9fb4733da807ad9200e8b7af

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

TODO: Add examples using Docker volumes...

## Status

WIP: This project is very early stage, a lot of things to be done...

[ ] setup examples
[ ] tests... a lot
[ ] add terraform file for AWS
[ ] ... you name it

Any feedback is welcome

