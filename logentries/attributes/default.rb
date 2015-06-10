default[:logentries][:logs][:chefclient] = { "filename" => '/var/log/chef/client.log', 'name' => 'chef-client.log' }
default[:logentries][:logs][:cloudinit] = { "filename" => '/var/log/cloud-init.log', 'name' => 'cloud-init.log' }
default[:logentries][:logs][:kern] = { "filename" => '/var/log/kern.log', 'name' => 'kern.log' }

default[:logentries][:logsets][:syslog] = { "filename" => '/var/log/syslog', 'name' => 'syslog' }
