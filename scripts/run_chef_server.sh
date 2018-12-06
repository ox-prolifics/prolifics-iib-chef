#!/bin/bash -xe

sysctl -w kernel.shmmax=17179869184 # for postgres 
/opt/chef-server/embedded/bin/runsvdir-start &
# do not use 'chef-server-ctl start' instead

if [ x"$(hostname)" != x"$(grep server_name /etc/chef-server/chef-server-running.json | sed 's/.*\"\(.*\)\".*\"\(.*\)\".*/\2/')" ]; then
    echo "Hostname changed, chef-server must be reconfigured"
    # if it fails, let someone in to correct it or find error.
    chef-server-ctl reconfigure || /bin/bash
fi

tail -F /opt/chef-server/embedded/service/*/log/current
