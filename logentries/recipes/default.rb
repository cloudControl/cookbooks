#
# Author:: Tobias Wilken <tw@cloudcontrol.de>
# Cookbook Name:: logentries
# Recipe:: default
#
# Copyright 2012 cloudControl GmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

apt_repository "logentries" do
    uri "http://rep.logentries.com/"
    distribution node['lsb']['codename']
    components [ "main" ]
    keyserver "keyserver.ubuntu.com"
    key "C43C79AD"
    action :add
end

package "logentries"
package "logentries-daemon"

# Some logs go into a logset, some go into the host. The config template
# is required for the ones that go into the logset

directory "/etc/le" do
  owner 'root'
  group 'root'
  mode '0775'
end

template "/etc/le/config" do
  source "config.erb"
  mode '0600'
  owner 'root'
  group 'root'
  action :create_if_missing
end

service 'logentries' do
  action :enable
  subscribes :restart, "template[/etc/le/config]", :delayed
end

le = Logentries.new(cookbook_name, recipe_name, run_context)

ruby_block "Register the host with logentries" do
  block do
    le_databag = Chef::EncryptedDataBagItem.load "logentries", node[:env]
    le.register le_databag['userkey'], node[:hostname]
  end
end

# Use the regular follow command for the logs that are more useful per host

ruby_block "Follow the logs" do
  block do
    node[:logentries][:logs].each { |key, log| le.follow log }
  end
end
