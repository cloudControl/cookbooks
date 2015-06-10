class Logentries < Chef::Recipe
  # Register the host with the given hostname via userkey with logentries
  def register(userkey, hostname)
    execute "le register --user-key #{userkey} --name='#{hostname}'" do
      not_if "cat /etc/le/config | grep agent-key"
    end
  end

  # Follows the given log, given by filename, name and type
  # - checks if we are already following this log
  def follow(log)
    Chef::Log.info "follow log #{log[:filename]}"
    execute "le follow '#{log[:filename]}' --name=#{log[:name]}" do
      not_if "le followed #{log[:filename]}"
    end
  end
end
