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

# Add the logentries repository
apt_repository "logentries" do
    uri "http://rep.logentries.com/"
    distribution node['lsb']['codename']
    components [ "main" ]
    keyserver "keys.gnupg.net"
    key "C43C79AD"
    action :add
end

# Install the logentries package
package "logentries"

# Get the logentries credentials from an enrypted data bag
le_databag = Chef::EncryptedDataBagItem.load "logentries", node[:env]

le = Logentries.new(cookbook_name, recipe_name, run_context)

# Register the host with logentries
le.register le_databag['userkey'], node[:hostname]

# Install the logentries-daemon package
package "logentries-daemon"

# Follow the given logs
node[:logentries][:logs].each { |key, log| le.follow log }

# Restart the logentries agent
service "logentries" do
	action :restart
	not_if "test -e /etc/le/config"
end
