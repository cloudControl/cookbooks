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
    components ["main"]
    keyserver "keys.gnupg.net"
    key "C43C79AD"
    action :add
end

# Install the logentries package
package "logentries"

# Get the logentries credentials from an enrypted data bag
le_databag = Chef::EncryptedDataBagItem.load("logentries", node[:env])

# Register the host with logentries
execute "le register --user-key #{le_databag['userkey']}  --name='#{node[:hostname]}'" do
  not_if "test -e /etc/le/config"
end

# Install the logentries-daemon package
package "logentries-daemon"

# Follow the given logs
class Chef::Recipe
  include Le
end
node[:logentries][:logs].each do |log|
  follow(log)
end

# Restart the logentries agent
execute "service logentries restart" do
  not_if "test -e /etc/le/config"
end