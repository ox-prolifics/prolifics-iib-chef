# iib

Details:
Cookbook accepts a license for a "shared" IIB installation so the created workpath is: /var/mqsi
Installs IIB. 

Two types of brokers can be created depending on the chosen recipe:
1: a Broker that leverages WMQ
2: a Broker that does not leverage WMQ.

End Result:
A broker and broker server will be running

Assumptions:
1- More than 1G of space exist in the /tmp directory
2- More than 1.6G of space exist for the IIB target directory
3- Installs on Linux 6.x
4- Install binaries located on file system.  Set location in cookbook attribute file

Current limitations:
If a broker is deleted (i.e. mqsideletebroker IBNODE), than you must manually delete any server directory that was previously configured with this node.  IIB script mqsideletebroker does not remove any broker servers in the /var/mqsi/config/<broker_name> directory.  This manual deletion is necessary to ensure a proper cleanup before re-running this cookbook as a guard is evaluated during the creation of a broker's server.

How to run:
chef-client --local-mode --runlist 'recipe[iib::create_broker_w_mq]'
chef-client --local-mode --runlist 'recipe[iib::create_broker_wo_mq]'

How to verify:
examine Linux system log: /var/log/messages
launch IIB admin console: http://localhost:4414

Dependencies:
mqv8 cookbook - for create_broker_w_mq recipe

To re-run this cookbook where the intent is to re-create the IIB environment from scratch (except removes WMQ):
-- su mqbrkusr
1- source <IIB_HOME>/server/bin/mqsiprofile
2- <IIB_HOME>/server/bin/mqsistop IBNODE
3- <IIB_HOME>/server/bin/mqsideletebroker IBNODE
-- su root (exit mqbrkusr)
4- rm -rf /var/mqsi
5- rm -rf /opt/IBM/iib*
6- userdel mqbrkusr
7- groupdel mqbrkrs
8- rm -rf /home/mqbrkusr
-- su mqm
9- /opt/mqm/bin/endmq -i IIB_QM
10 - /opt/mqm/bin/dltmqm IIB_QM



