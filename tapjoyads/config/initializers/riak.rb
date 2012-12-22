Riak.escaper = "cgi"
if Rails.env.production?
  $riak = Riak::Client.new(:protocol => 'pbc', :nodes => RIAK_NODES)
  $riak_devices = Riak::Client.new(:protocol => 'pbc', :nodes => DEVICE_RIAK_NODES)
else
  $riak = $riak_devices = Riak::Client.new
end
