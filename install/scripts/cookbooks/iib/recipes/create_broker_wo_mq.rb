#
# Cookbook Name:: iib
# Recipe:: create_broker_wo_mq
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

# Purpose:
# - Creates a broker 
# - Starts the broker
# - Creates a broker server

iib_user = node[:iib][:user]
iib_home = node[:iib][:home_dir]
iib_nodename = node[:iib][:node1][:name]
iib_node_svrname = node[:iib][:node1][:server1][:name]

include_recipe "iib::install"

######################################
# Create the broker
# create a broker server and start it
######################################

bash 'create_broker' do
   environment "CLASSPATH" => "#{iib_home}/common/classes/IntegrationAPI.jar:#{iib_home}/server/classes/brokerutil.jar"
   user iib_user
   group 'mqbrkrs'
   code <<-EOH
      #set up the IIB command environment
      source #{iib_home}/server/bin/mqsiprofile

      #create the integration node
      mqsicreatebroker #{iib_nodename}
  EOH
  not_if { ::Dir.exists?("/var/mqsi/registry/#{iib_nodename}") }
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
     #{iib_home}/server/bin/mqsilist | grep "node '#{iib_nodename}' is stopped" 
     if [ $? -ne 0 ]; then
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






