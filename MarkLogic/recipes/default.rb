#
# Cookbook Name:: MarkLogic
# Recipe:: default
#
# Copyright 2012, Zynx Health
#
# All rights reserved - Do Not Redistribute
#

#yum_package "glibc.i686"

remote_file "/tmp/MarkLogic-5.0-3.x86_64.rpm" do
  source "http://community.marklogic.com/download/binaries/5.0/MarkLogic-5.0-3.x86_64.rpm"
  action :create_if_missing	  
  mode "0777"
end
case node["platform"]
 when "centos","redhat","fedora"
	yum_package "glibc.i686"
	package "MarkLogic" do
	  action :install
	  source "/tmp/MarkLogic-5.0-3.x86_64.rpm"
	  provider Chef::Provider::Package::Rpm
	end
 when "ubuntu", "debian"
	script "clean_convert_install" do
	 interpreter "bash"
         user "root"
	 code <<-EOH
	 dpkg --purge marklogic
	 rm -rf /opt/MarkLogic
 	 apt-get -y install alien 
	 alien --to-deb --verbose /tmp/MarkLogic-5.0-3.x86_64.rpm
         dpkg -i marklogic_5.0-4_amd64.deb
       EOH
     end
end

script "nuke_MarkLogic_config" do
  interpreter "bash"
  user "root"
  code <<-EOH
  rm -rf /var/opt/MarkLogic
  EOH
end

script "short_circuit_XEN" do
  interpreter "bash"
  user "root"
  code <<-EOH
  sed -i.bak -e '1,$s/xen/Xxen/' /etc/sysconfig/MarkLogic
  EOH
end

service "MarkLogic" do
  action :restart
end

script "install_lic_key" do 
  interpreter "bash"
  user "root"
  code <<-EOH
sleep 5
wget -SO - 'http://localhost:8001/license-go.xqy?licensee=Zynx+Health+Inc+-+Galen+Project+-+Production+or+Development&license-key=9E6A-6853-CA55-D150-C6A6-35BA-A5AD-4DEB-DBF0-3000&ok=ok'
  EOH
end

service "MarkLogic" do
  action :restart
end

script "accept_lic" do 
  interpreter "bash"
  user "root"
  code <<-EOH
sleep 5
wget -SO - 'http://localhost:8001/agree-go.xqy?ok=accept&accepted-agreement=standard'
  EOH
end


service "MarkLogic" do
  action :restart
end

script "marklogic_initialize" do 
  interpreter "bash"
  user "root"
  code <<-EOH
sleep 5
wget -SO - 'http://localhost:8001' 2>&1 | grep '^Location: initialize-admin.xqy' 
if [ $? -eq 0 ]; then
wget -t 25 -SO - 'http://localhost:8001/initialize-go.xqy?ok=ok'
else 
true
fi
sleep 10
EOH
end

service "MarkLogic" do
  action :restart
end

script "marklogic_configure" do 
  interpreter "bash"
  user "root"
  code <<-EOH
sleep 5
curl 'http://localhost:8001/security-install-go.xqy?ok=ok&user=admin&password1=#{node[:marklogic][:admin_pwd]}&password2=#{node[:marklogic][:admin_pwd]}&realm=public'
  EOH
end







