Riak.escaper = "cgi"
if Rails.env.production?
  $riak = Riak::Client.new(:protocol => 'pbc', :nodes => RIAK_NODES)
  $riak_devices = Riak::Client.new(:protocol => 'pbc', :nodes => DEVICE_RIAK_NODES)
else
  $riak = $riak_devices = if ENV['RIAK_HOST']
    Riak::Client.new(
      :protocol => 'pbc',
      :nodes    => [{:host => ENV['RIAK_HOST']}]
    )
  else
    Riak::Client.new
  end
end
