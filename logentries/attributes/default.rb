default[:logentries][:logs][:syslog] = { "filename" => '/var/log/syslog', 'name' => 'syslog', 'type' => 'syslog' }
default[:logentries][:logs][:chefclient] = { "filename" => '/var/log/chef/client.log', 'name' => 'chef-client.log', 'type' => 'syslog' }
default[:logentries][:logs][:cloudinit] = { "filename" => '/var/log/cloud-init.log', 'name' => 'cloud-init.log', 'type' => 'syslog' }
