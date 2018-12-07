# location of the directory used to uncompress the .gz
default[:iib][:scratch_dir] = "/tmp/IIB_scratch"

# location to install IIB dir
default[:iib][:install_dir] = "/opt/IBM"

# the IIB home dir.  Note! this must include the install IIB dir plus the root directory name of the uncompressed .gz
default[:iib][:home_dir] = "/opt/IBM/iib-10.0.0.1"

# location of the installation binaries on the file system
default[:iib][:zip] = "/software/IIBv10/IIB_10.0.0.1_LINUX_X86-64.tar.gz"

# the owner to be associated with the IIB install
default[:iib][:user] = "mqbrkusr"

# name of the IIB QM that will be created
default[:iib][:qm] = "IIB_QM"
default[:iib][:qmha] = "IIB_QM_HA"

# name of the broker to create
default[:iib][:node1][:name] = "IBNODE"
default[:iib][:node1][:nameha] = "IBNODE_HA"

# name of the broker server to create
default[:iib][:node1][:server1][:name] = "IBSVR1"
default[:iib][:node1][:server1][:nameha] = "IBSVR1_HA"

