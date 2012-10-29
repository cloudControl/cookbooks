#
# Author:: Tobias Wilken <tw@cloudcontrol.de>
# Cookbook Name:: serverdensity
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

# Add the serverdensity repository
apt_repository "serverdensity" do
    uri "http://www.serverdensity.com/downloads/linux/deb"
    distribution "all"
    components [ "main" ]
    key "https://www.serverdensity.com/downloads/boxedice-public.key"
    action :add
end

# Install the sd-agent package
package "sd-agent"

# Get the serverdensity credentials from an enrypted data bag
sd_databag = Chef::EncryptedDataBagItem.load "serverdensity", node[:env]

# Register the host with serverdensity
sd = ServerDensity.new
sd.register(sd_databag['username'], sd_databag['password'], sd_databag['sd_url'], sd_databag['api_key'], node)
sd.addAlerts(sd_databag['username'], sd_databag['password'], sd_databag['sd_url'], sd_databag['api_key'], node)

# Creates the config file
template "/etc/sd-agent/config.cfg" do
    source "sd-agent-config.erb"
    owner "sd-agent"
    group "sd-agent"
    mode 0500
    variables({
      :sd_url => sd_databag['sd_url'],
      :agent_key => node[:serverdensity][:agent_key],
      :mongodb_server => node[:serverdensity][:mongodb_server],
      :mongodb_dbstats => node[:serverdensity][:mongodb_dbstats],
      :mongodb_replset => node[:serverdensity][:mongodb_replset]
    })
    notifies :restart, "service[sd-agent]"
end

# Starts the agent
service "sd-agent" do
  action :nothing
end
