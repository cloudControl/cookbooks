class Logentries < Chef::Recipe
  # Register the host with the given hostname via userkey with logentries
  def register(userkey, hostname)
    execute "le register --user-key #{userkey}  --name='#{hostname}'" do
      not_if "test -e /etc/le/config"
    end
  end
  
  
  # Follows the given log, given by filename, name and type
  # - checks if we already following this log
  def follow(log)
    Chef::Log.info("follow log #{log[:filename]}")
    execute "le follow '#{log[:filename]}' --name=#{log[:name]} --type=#{log[:type]}" do
      not_if "le followed #{log[:filename]}"
    end
  end
end
