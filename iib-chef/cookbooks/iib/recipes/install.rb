#
# Cookbook Name:: iib
# Recipe:: install_iib
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

# Purpose: 
# - Unpacks the product to a designated target location
# - Accepts the license and creates the mqbrkrs group
# - Creates a IIB user and assigns to the mqbrkrs and mqm groups
# - Sets the IIB installation ownership to designated IIB User and mqbrkrs group

######################################
# Establish IIB user 
######################################
iib_user = node[:iib][:user]
iib_userhome = "/home/#{iib_user}"

group 'mqbrkrs' do
  gid 601
end

user iib_user do
  uid 601
  gid 601 
  home iib_userhome
  manage_home true
  system true
end

#+++++++++++++++++++++++++++++++++++++++++
# Unpacks Installation Binaries Assembly to temp install location
# then unpacks assembly to target location
#+++++++++++++++++++++++++++++++++++++++++

unpack_dir = node[:iib][:scratch_dir]
install_target_dir = node[:iib][:install_dir]
iib_home = node[:iib][:home_dir]


directory unpack_dir do
  action :create
end

directory install_target_dir do
  action :create
end 

bin_name = "IIB_10.0.0.1_LINUX_X86-64.tar.gz"

execute "uncompress_IIB_installation_tarball_to_scratch dir" do
  cwd unpack_dir
  command "/HA/scripts/getIIB.sh && tar -zxf #{bin_name}"
  # command "tar -zxf #{node[:iib][:zip]}"
  not_if { ::Dir.exists? "#{iib_home}" }
end

execute "uncompress_IIB_installation_tarball_to_target dir" do
  cwd "#{unpack_dir}/EAsmbl_image"
  command "tar -zxf iib*.tar.gz -C #{install_target_dir}"
  not_if { ::Dir.exists? "#{iib_home}" }
end

execute "remove_unpack_dir" do
  command "rm -rf #{unpack_dir}"
end


######################################
# Accept license and create mqbrkrs group 
######################################
iib_home = node[:iib][:home_dir]

bash 'iib_license_acceptance' do
  code "#{iib_home}/iib make registry global accept license silently"
  not_if { ::File.exists? "#{iib_home}/license/status.dat" }
end



######################################
# Set IIB installation ownership
######################################
bash 'change_owner' do
  user 'root'
  code "chown -R #{iib_user}:mqbrkrs #{iib_home} /var/mqsi"
end

