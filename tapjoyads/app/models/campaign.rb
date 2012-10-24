class Campaign < SimpledbResource
  include RiakMirror
  mirror_configuration :riak_bucket_name => "campaign"

  self.domain_name = 'campaign'
end
