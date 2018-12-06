#
# Cookbook Name:: iib
# Recipe:: create_broker_w_mq_ha
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

# Purpose:
# - Does initial setup if leader node, otherwise does follower node setup
# - Configures the MQ environment (creates a QM, adds IIB user to mqm group)
# - Creates a broker and associates it with the IIB QM
# - Creates the broker system queues
# - Starts the broker
# - Creates a broker server


iib_qm = node[:iib][:qmha]
iib_user = node[:iib][:user]
iib_home = node[:iib][:home_dir]
iib_nodename = node[:iib][:node1][:nameha]
iib_node_svrname = node[:iib][:node1][:server1][:nameha]
mq_home = '/opt/mqm'

include_recipe "iib::install"
include_recipe "mqv8::install"



######################################
# Configure group membership 
######################################
bash 'configure_groups' do
  code <<-EOH
    usermod -a -G mqm #{iib_user}
    usermod -a -G mqbrkrs mqm 
  EOH
end

######################################
# Configure the MQ environment
######################################

CACHE = Chef::Config[:file_cache_path]

mqsc_file = ::File.join(CACHE, "iib_mqsc.in")
  template mqsc_file do
    source "iib_mqsc.in.erb"
    owner iib_user
    variables({
      :iib_qmgr => iib_qm
    })
  end

bash 'create_dirs' do

  code <<-EOH
    mkdir -p /HA/logs /HA/qmgrs /HA/iib
    chown -R mqm:mqm /HA/logs /HA/qmgrs
    chown -R mqbrkusr:mqbrkrs /HA/iib
    chmod -R 777 /HA
  EOH
  not_if "test -d /HA/logs && test -d /HA/qmgrs && test -d /HA/iib"
end

bash 'create_iib_qm' do
  user 'mqm'
  group 'mqm'
  returns [0,30]
  code <<-EOH

     PATH=$PATH:/opt/mqm/bin

     if [ -f /HA/addqminf.rsp ]; then
       #follower node, configure as a standby instance
       eval $(cat /HA/addqminf.rsp)
       sleep 1
       strmqm -x #{iib_qm}
       sleep 1
       dspmq
     else
       #leader/first node, create qm and rsp file for use in creating followers
       crtmqm -ld /HA/logs -md /HA/qmgrs -q #{iib_qm} 
       dspmqinf -o command #{iib_qm} > /HA/addqminf.rsp
       strmqm -x #{iib_qm}
       runmqsc #{iib_qm} < #{mqsc_file}
     fi
      
  EOH
  not_if "/opt/mqm/bin/dspmq | grep #{iib_qm}"
end



#####################################################
# Create the broker, associate it with designated QM,
# create a broker server and start it
#####################################################

bash 'create_broker' do
   returns [0,30,49]
   code <<-EOH
      export PATH=$PATH:/opt/mqm/bin
      source #{iib_home}/server/bin/mqsiprofile

      if [ -s /HA/iib/mqsi/components/#{iib_nodename}/config/#{iib_nodename} ]; then
        #add as a follower node
        su #{iib_user} -c "mqsiaddbrokerinstance #{iib_nodename} -e /HA/iib"
        su mqm -c "#{mq_home}/bin/endmqm -x #{iib_qm}"
      else
        #create the integration node to be managed as an mq service
        su #{iib_user} -c "mqsicreatebroker #{iib_nodename} -q #{iib_qm} -e /HA/iib -d defined"
        su mqm -c "#{mq_home}/bin/endmqm -i #{iib_qm}"
      fi
      sleep 1
      su mqm -c "#{mq_home}/bin/strmqm -x #{iib_qm}"
  EOH
  not_if " test -d /var/mqsi/registry/#{iib_nodename}" 
end

######################################
# Create the broker system queues
######################################
bash 'create_queues' do
   code <<-EOH
      export PATH=$PATH:/opt/mqm/bin
      source #{iib_home}/server/bin/mqsiprofile

      # create a set of default system queues to be created on the QM that is associated with the integration node.
      # The default system queues are used to store information about in-flight messages.
      su #{iib_user} -c "#{iib_home}/server/sample/wmq/iib_createqueues.sh #{iib_qm} mqbrkrs"
      su mqm -c "#{mq_home}/bin/endmqm -i #{iib_qm}"
      su mqm -c "#{mq_home}/bin/strmqm -x #{iib_qm}"
      sleep 1  #required to allow everything a moment a startup; lost 16 hours figuring this out :-/
   EOH
   not_if " test -f '/HA/qmgrs/#{iib_qm}/queues/SYSTEM!BROKER!TIMEOUT!QUEUE' "
end

######################################
# create a server
######################################
bash 'create_broker_server' do
   guard_interpreter :bash
   code <<-EOH
      #set up the IIB command environment

      #add a new integration server to the integration node.  The server is started automatically.
      su - #{iib_user} -c "source #{iib_home}/server/bin/mqsiprofile && mqsicreateexecutiongroup #{iib_nodename} -e #{iib_node_svrname}"
  EOH
  only_if "source #{iib_home}/server/bin/mqsiprofile &&  mqsilist | grep BIP1295I"
  not_if "source #{iib_home}/server/bin/mqsiprofile && mqsilist #{iib_nodename} | grep #{iib_node_svrname} "
end


