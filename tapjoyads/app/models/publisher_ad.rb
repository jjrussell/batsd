class PublisherAd < SimpledbResource
  include RiakMirror
  mirror_configuration :riak_bucket_name => "publisher_ad"

  self.domain_name = 'publisher_ad'
end
