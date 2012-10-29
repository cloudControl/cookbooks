require 'rest_client'
require 'json'

class ServerDensity
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
      node.set[:serverdensity][:agent_key] = parsed_output[:data][:agentKey]
      node.set[:serverdensity][:deviceId] = parsed_output[:data][:deviceId]
      node.set[:serverdensity][:deviceIdOld] = parsed_output[:data][:deviceIdOld]
    end
  end

  # Add alerts to the given host
  def addAlerts(username, password, sd_url, api_key, node)
    addAlert(node, username, password, sd_url, api_key, :checkType => "noData", :comparison => "=", :triggerThresholdMin => "5")
    addAlert(node, username, password, sd_url, api_key, :checkType => "loadAvrg", :comparison => ">", :triggerThreshold => 2 * node[:cpu][:total].to_f)
    addAlert(node, username, password, sd_url, api_key, :checkType => "memPhysUsed", :comparison => ">", :triggerThreshold => 0.85 * node[:memory][:total].to_f / 1000) # In MB
    addAlert(node, username, password, sd_url, api_key, :checkType => "memSwapUsed", :comparison => ">", :triggerThreshold => 0.25 * node[:memory][:swap][:total].to_f / 1000) # In MB
    addAlert(node, username, password, sd_url, api_key, :checkType => "diskUsagePercent", :comparison => ">=", :triggerThreshold => "75%", :diskUsageMountPoint => "/")
  end

  # Add alerts to the given host
  def addAlert(node, username, password, sd_url, api_key, options={})
    # Check if the node has already the alert added
    if node['serverdensity'].has_key? 'deviceIdOld' and not node['serverdensity'].has_key? options[:checkType]
      Chef::Log.info "Add alert: #{options[:checkType]}"

      # Check if the node has already alerts added
      url = "https://#{username}:#{password}@api.serverdensity.com/1.4/alerts/add?account=#{sd_url}&apiKey=#{api_key}"
      options[:userId] ||= [ "group" ]
      options[:serverId] ||= node[:serverdensity][:deviceIdOld]
      options[:notificationType] ||= [ "email", "iphonepush", "androidpush" ]
      options[:notificationFixed] = true if options[:notificationFixed].nil?
      options[:notificationDelayImmediately] = true if options[:notificationDelayImmediately].nil?
      options[:notificationFrequencyOnce] = true if options[:notificationFrequencyOnce].nil?

      begin
        RestClient.post url, options
      rescue RestClient::BadRequest => error
        puts error.message
        puts error.response
        raise
      end
      node.set[:serverdensity][ options[:checkType] ] = true
    end
  end
end
