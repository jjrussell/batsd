class Campaign < SimpledbResource
  include RiakMirror
  mirror_configuration :riak_bucket_name => "campaign", :read_from_riak => true

  self.domain_name = 'campaign'
end
