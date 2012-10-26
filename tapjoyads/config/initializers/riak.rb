Riak.escaper = "cgi"
if Rails.env.production?  
  $riak = Riak::Client.new(:protocol => 'pbc', :nodes => RIAK_NODES)
else
  $riak = Riak::Client.new
end