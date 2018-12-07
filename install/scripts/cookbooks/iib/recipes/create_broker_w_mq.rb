#
# Cookbook Name:: iib
# Recipe:: create_broker_w_mq
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

# Purpose:
# - Configures the MQ environment (creates a QM, adds IIB user to mqm group)
# - Creates a broker and associates it with the IIB QM
# - Creates the broker system queues
# - Starts the broker
# - Creates a broker server


iib_qm = node[:iib][:qm]
iib_user = node[:iib][:user]
iib_home = node[:iib][:home_dir]
iib_nodename = node[:iib][:node1][:name]
iib_node_svrname = node[:iib][:node1][:server1][:name]

include_recipe "iib::install"
include_recipe "mqv8::install"

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

bash 'create_iib_qm' do
  #user iib_user
  user 'mqm'
  group 'mqm'
  code <<-EOH
     /opt/mqm/bin/crtmqm -q -ll -u #{iib_qm}.DLQ #{iib_qm}
     /opt/mqm/bin/strmqm #{iib_qm}
     /opt/mqm/bin/runmqsc #{iib_qm} < #{mqsc_file}
  EOH
  not_if "/opt/mqm/bin/dspmq | grep #{iib_qm}"
end

bash 'add_iib_user_to_mqm_group' do
  code <<-EOH
    usermod -a -G mqm #{iib_user}  #adding to secondary group
    EOH
end

######################################
# Restart IIB QM
# Need to restart IIB_QM since we added mqbrkusr to the mqm group otherwise will get permission denied when 
# later running the iib_createqueues.sh 
######################################
mq_home = '/opt/mqm'

bash 'restart_IIB_QM' do
  user 'mqm'
  group 'mqm'
  code <<-EOH
     #{mq_home}/bin/endmqm -i #{iib_qm}
     #{mq_home}/bin/strmqm #{iib_qm}
  EOH
end

######################################
# Create the broker, associate it with designated QM,
# create a broker server and start it
######################################

bash 'create_broker' do
   environment "CLASSPATH" => "#{iib_home}/common/classes/IntegrationAPI.jar:#{iib_home}/server/classes/brokerutil.jar"
   user iib_user
   group 'mqbrkrs'
   code <<-EOH
      export PATH=$PATH:/opt/mqm/bin
      #set up the IIB command environment
      source #{iib_home}/server/bin/mqsiprofile

      #create the integration node
      mqsicreatebroker #{iib_nodename} -i #{iib_user} -a #{iib_user} -q #{iib_qm}
  EOH
  not_if { ::Dir.exists?("/var/mqsi/registry/#{iib_nodename}") }
end

######################################
# Create the broker system queues
######################################
bash 'create_queues' do
   environment "CLASSPATH" => "#{iib_home}/common/classes/IntegrationAPI.jar:#{iib_home}/server/classes/brokerutil.jar"
   user iib_user
   group 'mqm'
   code <<-EOH
      export PATH=$PATH:/opt/mqm/bin
      #set up the IIB command environment
      source #{iib_home}/server/bin/mqsiprofile

      # create a set of default system queues to be created on the QM that is associated with the integration node.
      # The default system queues are used to store information about in-flight messages.
      #{iib_home}/server/sample/wmq/iib_createqueues.sh #{iib_qm} mqbrkrs
   EOH
   not_if { ::File.exist?("/var/mqm/qmgrs/#{iib_qm}/queues/SYSTEM!BROKER!TIMEOUT!QUEUE") }
end

######################################
# Start the IIB Broker 
######################################

# this creates a temporary status if IF the broker exists
bash 'output_status_file' do
   user iib_user
   group 'mqbrkrs'
   code <<-EOH
     source #{iib_home}/server/bin/mqsiprofile
     #{iib_home}/server/bin/mqsilist | grep "node '#{iib_nodename}' on queue manager '#{iib_qm}' is running" 
     if [ $? -ne 1 ]; then
        touch /tmp/broker_exists
     fi
   EOH
end

bash 'start_iib_node' do
   user iib_user
   group 'mqbrkrs'
   code <<-EOH
      #set up the IIB command environment
      source #{iib_home}/server/bin/mqsiprofile

      #start the integration node:
      #{iib_home}/server/bin/mqsistart #{iib_nodename}
  EOH
  # could not get this guard to work
  not_if { File.exist?('/tmp/broker_exists')}
end

# This removes the temporary status file IF it exists
file '/tmp/broker_exists' do
  action :delete
end

######################################
# create a server
######################################
bash 'create_broker_server' do
   user iib_user
   group 'mqbrkrs'
   code <<-EOH
      #set up the IIB command environment
      source #{iib_home}/server/bin/mqsiprofile

      #add a new integration server to the integration node.  The server is started automatically.
      mqsicreateexecutiongroup #{iib_nodename} -e #{iib_node_svrname}
  EOH
  # can't use this guard as even when a broker is deleted the configuration structure remains intact!
  not_if { ::File.exists? ::File.join('/var/mqsi/config/', "#{iib_nodename}", "#{iib_node_svrname}") }
end






