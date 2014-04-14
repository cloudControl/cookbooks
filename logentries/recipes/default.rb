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

le = Logentries.new(cookbook_name, recipe_name, run_context)

ruby_block "Register the host with logentries" do
  block do
    le_databag = Chef::EncryptedDataBagItem.load "logentries", node[:env]

    le.register le_databag['userkey'], node[:hostname]
  end
end

package "logentries-daemon"

ruby_block "Follow the logs" do
  block do
    node[:logentries][:logs].each { |key, log| le.follow log }
  end
end

# start the service if it isn't. We do it like this because logentries
# start borks if the service is already running.
service 'logentries' do
  action :start
  not_if 'service logentries status' # status returns 0 if the service is running
end
