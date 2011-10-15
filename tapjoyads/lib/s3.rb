class S3

  def self.bucket(bucket_name, create = false)
    s3     = AWS::S3.new
    bucket = s3.buckets[bucket_name]
    bucket = s3.buckets.create(bucket_name) if create && !bucket.exists?
    bucket
  end

end
