require 'rest_client'
require 'json'

class ServerDensity < Chef::Recipe
  def register(username, password, sd_url, api_key, node)
    # Check if the node is already registered
    unless node[:serverdensity].has_key? "agent_key"
      url = "https://#{username}:#{password}@api.serverdensity.com/1.4/devices/add?account=#{sd_url}&apiKey=#{api_key}"
      data = { "name" => node[:hostname], "group" => node[:serverdensity][:group].nil? ? node[:roles].first : node[:serverdensity][:group] }
      Chef::Log.info "Register: #{node[:hostname]}"
      begin
        response = RestClient.post url, data
      rescue RestClient::BadRequest => error
        puts error.message
        puts error.response
        raise
      end
      parsed_output = JSON.parse response.to_str
      node.set[:serverdensity][:agent_key] = parsed_output["data"]["agentKey"]
      node.set[:serverdensity][:deviceId] = parsed_output["data"]["deviceId"]
      node.set[:serverdensity][:deviceIdOld] = parsed_output["data"]["deviceIdOld"]
    end
  end

  def add_alerts(username, password, sd_url, api_key, node)
    add_alert(node, username, password, sd_url, api_key, :checkType => "noData", :comparison => "=", :triggerThresholdMin => "5", :notificationFixed => true, :notificationDelayImmediately => true, :notificationFrequencyOnce => true, :notificationType => [ "email", "iphonepush", "androidpush", "sms" ])
    add_alert(node, username, password, sd_url, api_key, :checkType => "loadAvrg", :comparison => ">", :triggerThreshold => 20 * node[:cpu][:total].to_f, :notificationFixed => true, :notificationDelayImmediately => true, :notificationFrequencyOnce => true, :notificationType => [ "email", "iphonepush", "androidpush", "sms" ])
    add_alert(node, username, password, sd_url, api_key, :checkType => "loadAvrg", :comparison => ">", :triggerThreshold => 10 * node[:cpu][:total].to_f, :notificationFixed => true, :notificationDelay => 5, :notificationFrequencyOnce => true)
    add_alert(node, username, password, sd_url, api_key, :checkType => "loadAvrg", :comparison => ">", :triggerThreshold => 5 * node[:cpu][:total].to_f, :notificationFixed => true, :notificationDelay => 15, :notificationFrequencyOnce => true)
    add_alert(node, username, password, sd_url, api_key, :checkType => "loadAvrg", :comparison => ">", :triggerThreshold => 2 * node[:cpu][:total].to_f, :notificationFixed => true, :notificationDelay => 60, :notificationFrequencyOnce => true)
    add_alert(node, username, password, sd_url, api_key, :checkType => "memCached", :comparison => "<", :triggerThreshold => 0.15 * node[:memory][:total].to_f / 1000, :notificationFixed => true, :notificationDelay => 5, :notificationFrequencyOnce => true) if mem_cached_ready(node)
    add_alert(node, username, password, sd_url, api_key, :checkType => "memSwapUsed", :comparison => ">", :triggerThreshold => 0.25 * node[:memory][:swap][:total].to_f / 1000, :notificationFixed => true, :notificationDelay => 5, :notificationFrequencyOnce => true) if mem_swap_used_ready(node)
    add_alert(node, username, password, sd_url, api_key, :checkType => "diskUsagePercent", :comparison => ">=", :triggerThreshold => "75%", :diskUsageMountPoint => "/", :notificationFixed => true, :notificationDelay => 5, :notificationFrequencyOnce => true)
    add_alert(node, username, password, sd_url, api_key, :checkType => "mysqlSecondsBehindMaster", :comparison => ">=", :triggerThreshold => 1500, :notificationFixed => true, :notificationDelayImmediately => true, :notificationFrequencyOnce => true) if node[:recipes].include? 'mysql::server'
  end

  def add_alert(node, username, password, sd_url, api_key, options={})
    # Check if the node has already the alert added
    key = if options[:pluginKey]
      "#{options[:checkType]}-#{options[:pluginKey]}-#{options.fetch(:triggerThreshold, "0")}"
    else
      "#{options[:checkType]}-#{options.fetch(:triggerThreshold, "0")}"
    end

    if node['serverdensity'].has_key? 'deviceIdOld' and not node['serverdensity'].has_key? key
      Chef::Log.info "Add alert: #{key}"

      # Check if the node has already alerts added
      url = "https://#{username}:#{password}@api.serverdensity.com/1.4/alerts/add?account=#{sd_url}&apiKey=#{api_key}"
      options[:userId] ||= [ "group" ]
      options[:serverId] ||= node[:serverdensity][:deviceIdOld]
      options[:notificationType] ||= [ "email", "iphonepush", "androidpush" ]

      begin
        RestClient.post url, options
      rescue RestClient::BadRequest => error
        puts error.message
        puts error.response
        raise
      end
      node.set[:serverdensity][ key ] = true
    end
  end

  def add_varnish()
    execute "serverdensity varnish plugin" do
      command "/usr/bin/sd-agent/plugins.py -u 50acc6d49cfe1e6e0a000001"
      user "root"
    end
  end

  def add_varnishstat()
    execute "serverdensity varnish plugin" do
      command "/usr/bin/sd-agent/plugins.py -u 50acc71d9cfe1e1c63000000"
      user "root"
    end
  end

  def add_supervisord_check(username, password, sd_url, api_key, node)
    execute "serverdensity supervisordcheck plugin" do
      command "/usr/bin/sd-agent/plugins.py -u 50cb621c9cfe1e563300000b"
      user "root"
    end

    add_alert(node, username, password, sd_url, api_key,
      :checkType => "SupervisordCheck",
      :comparison => "<",
      :triggerThreshold => "1",
      :pluginKey => "Running",
      :notificationFixed => true,
      :notificationDelay => 5,
      :notificationFrequencyOnce => true,
      :notificationType => [ "email", "iphonepush", "androidpush", "sms" ]
    )
  end

  def add_mysql_replication_check(username, password, sd_url, api_key, node)
    execute "serverdensity mysql replication plugin" do
      command "/usr/bin/sd-agent/plugins.py -u 514462939cfe1e164b000009"
      user "root"
    end
    add_alert(node, username, password, sd_url, api_key, :checkType => "MySQLReplication", :pluginKey => "Seconds_Behind_Master", :comparison => "<", :triggerThreshold => 0, :notificationFixed => true, :notificationDelayImmediately => true, :notificationFrequencyOnce => true, :notificationType => [ "email", "iphonepush", "androidpush", "sms" ])
    add_alert(node, username, password, sd_url, api_key, :checkType => "MySQLReplication", :pluginKey => "Slave_SQL_Running", :comparison => "<", :triggerThreshold => 1, :notificationFixed => true, :notificationDelayImmediately => true, :notificationFrequencyOnce => true, :notificationType => [ "email", "iphonepush", "androidpush", "sms" ])
    add_alert(node, username, password, sd_url, api_key, :checkType => "MySQLReplication", :pluginKey => "Slave_IO_Running", :comparison => "<", :triggerThreshold => 1, :notificationFixed => true, :notificationDelayImmediately => true, :notificationFrequencyOnce => true, :notificationType => [ "email", "iphonepush", "androidpush", "sms" ])
    add_alert(node, username, password, sd_url, api_key, :checkType => "MySQLReplication", :pluginKey => "Running", :comparison => "<", :triggerThreshold => 1, :notificationFixed => true, :notificationDelayImmediately => true, :notificationFrequencyOnce => true, :notificationType => [ "email", "iphonepush", "androidpush", "sms" ])
  end

  def mem_cached_ready(node)
    node[:uptime_seconds].to_f > 7200 or node[:memory][:cached].to_f > 0.25 * node[:memory][:total].to_f
  end

  def mem_swap_used_ready(node)
    node[:memory][:swap][:total].to_f > 0
  end

end
