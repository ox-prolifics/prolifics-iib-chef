#!/bin/bash

apt-get update 
DEBIAN_FRONTEND=noninteractive apt-get install -y wget  # https://github.com/docker/docker/issues/4032

# choose from: https://www.chef.io/download-open-source-chef-server-11/
# latest: www.opscode.com/chef/download-server?p=ubuntu&pv=12.04&m=x86_64&v=latest&prerelease=false&nightlies=false
cd /tmp && wget --content-disposition "http://www.opscode.com/chef/download-server?p=ubuntu&pv=12.04&m=x86_64&v=latest&prerelease=false&nightlies=false"
dpkg -i /tmp/chef-server*.deb

# Those demand --privileged option and currently `docker build` does not 
# support this (https://github.com/docker/docker/issues/1916), thus they 
# will be run at container first start (and any other hostname change). 
# sysctl -w kernel.shmmax=17179869184
# #/opt/chef-server/embedded/bin/runsvdir-start & 
# # configure as much as possible
# chef-server-ctl reconfigure

mv /scripts/run_chef_server.sh /usr/bin/run_chef_server.sh
chmod 755 /usr/bin/run_chef_server.sh