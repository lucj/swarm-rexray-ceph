## Purpose

Setup a Docker swarm cluster using REX-Ray and Ceph for the orchestration of the storage layer

## Prerequisites

1. Get Ansible from [http://docs.ansible.com/ansible/latest/intro_installation.html](http://docs.ansible.com/ansible/latest/intro_installation.html)

2. Setup the infrastructure 

In this first version, I've only tested with DigitalOcean droplets:
* one manager used to deploy a Ceph cluster
* three nodes participating to the Ceph cluster and running Docker swarm

> On each of the 3 nodes, an additonal DigitalOcean volume has been added. The 3 volumes will be used by Ceph

3. Modify your local /etc/hosts to define the following machine:
* adm
* node1
* node2
* node3

## Deploy

The cluster can be deployed with the following command

```
ansible-playbook -i inventory.ini -u root main.yml
```

## Status

WIP: This project is very early stage...

Any feedback is welcome

