chef_certificate = File.join(ENV['HOME'], '.chef', 'client.pem')

if File.exists?(chef_certificate)
  Chef::Config[:node_name]       = ENV['CHEF_NODE_NAME']
  Chef::Config[:chef_server_url] = ENV['CHEF_SERVER_URL']
  Chef::Config[:client_key]      = chef_certificate
end
