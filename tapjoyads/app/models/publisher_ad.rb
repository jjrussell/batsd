class PublisherAd < SimpledbResource
  include RiakMirror
  mirror_configuration :riak_bucket_name => "publisher_ad", :read_from_riak => true

  self.domain_name = 'publisher_ad'
end
