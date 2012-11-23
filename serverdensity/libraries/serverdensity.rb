require 'rest_client'
require 'json'

class ServerDensity < Chef::Recipe
  # Register the host with serverdensity
  def register(username, password, sd_url, api_key, node)
    # Check if the node is already registered
    unless node[:serverdensity].has_key? "agent_key"
      url = "https://#{username}:#{password}@api.serverdensity.com/1.4/devices/add?account=#{sd_url}&apiKey=#{api_key}"
      data = { "name" => node[:hostname], "group" => node[:roles].first }
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

  # Add alerts to the given host
  def addAlerts(username, password, sd_url, api_key, node)
    addAlert(node, username, password, sd_url, api_key, :checkType => "noData", :comparison => "=", :triggerThresholdMin => "5", :notificationFixed => true, :notificationDelayImmediately => true, :notificationFrequencyOnce => true)
    addAlert(node, username, password, sd_url, api_key, :checkType => "loadAvrg", :comparison => ">", :triggerThreshold => 10 * node[:cpu][:total].to_f, :notificationFixed => true, :notificationDelay => 5, :notificationFrequencyOnce => true)
    addAlert(node, username, password, sd_url, api_key, :checkType => "loadAvrg", :comparison => ">", :triggerThreshold => 5 * node[:cpu][:total].to_f, :notificationFixed => true, :notificationDelay => 15, :notificationFrequencyOnce => true)
    addAlert(node, username, password, sd_url, api_key, :checkType => "loadAvrg", :comparison => ">", :triggerThreshold => 2 * node[:cpu][:total].to_f, :notificationFixed => true, :notificationDelay => 60, :notificationFrequencyOnce => true)
    addAlert(node, username, password, sd_url, api_key, :checkType => "memCached", :comparison => "<", :triggerThreshold => 0.15 * node[:memory][:total].to_f / 1000, :notificationFixed => true, :notificationDelay => 5, :notificationFrequencyOnce => true)
    addAlert(node, username, password, sd_url, api_key, :checkType => "memSwapUsed", :comparison => ">", :triggerThreshold => 0.25 * node[:memory][:swap][:total].to_f / 1000, :notificationFixed => true, :notificationDelay => 5, :notificationFrequencyOnce => true)
    addAlert(node, username, password, sd_url, api_key, :checkType => "diskUsagePercent", :comparison => ">=", :triggerThreshold => "75%", :diskUsageMountPoint => "/", :notificationFixed => true, :notificationDelay => 5, :notificationFrequencyOnce => true)
  end

  # Add alerts to the given host
  def addAlert(node, username, password, sd_url, api_key, options={})
    # Check if the node has already the alert added
    if node['serverdensity'].has_key? 'deviceIdOld' and not node['serverdensity'].has_key? "#{options[:checkType]}-#{options.fetch(:triggerThreshold, "0")}"
      Chef::Log.info "Add alert: #{options[:checkType]}-#{options.fetch(:triggerThreshold, "0")}"

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
      node.set[:serverdensity][ "#{options[:checkType]}-#{options.fetch(:triggerThreshold, "0")}" ] = true
    end
  end

  # Add varnish plugin
  def addVarnish()
    execute "serverdensity varnish plugin" do
        command "/usr/bin/sd-agent/plugins.py -u 50acc6d49cfe1e6e0a000001"
        user "root"
    end
  end

  # Add varnishstat plugin
  def addVarnishstat()
    execute "serverdensity varnish plugin" do
      command "/usr/bin/sd-agent/plugins.py -u 50acc71d9cfe1e1c63000000"
      user "root"
    end
  end

  # Add supervisord plugin
  def addSupervisord()
    execute "serverdensity varnish plugin" do
      command "/usr/bin/sd-agent/plugins.py -u 50accbdd9cfe1e5576000002"
      user "root"
    end
  end

  # Add supervisordmemory plugin
  def addSupervisordMemory()
    execute "serverdensity varnish plugin" do
      command "/usr/bin/sd-agent/plugins.py -u 50accc3a9cfe1e651e000001"
      user "root"
    end
  end
end
