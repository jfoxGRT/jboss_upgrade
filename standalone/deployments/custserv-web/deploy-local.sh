#!/bin/sh

sudo /sbin/service mongrel_cluster stop
sudo rm -rf /u/apps/custserv/current
sudo mkdir -p /u/apps/custserv/current
sudo cp -r . /u/apps/custserv/current
sudo chown -R mongrel.mongrel /u/apps/custserv/current
sudo /sbin/service mongrel_cluster start