syslog = Hash["filename"=>'/var/log/syslog', 'name'=>'syslog', 'type'=>'syslog']
chefclient = Hash["filename"=>'/var/log/chef/client.log', 'name'=>'chef-client.log', 'type'=>'syslog']
cloudinit = Hash["filename"=>'/var/log/cloud-init.log', 'name'=>'cloud-init.log', 'type'=>'syslog']

default[:logentries][:logs] = [syslog, chefclient, cloudinit]
