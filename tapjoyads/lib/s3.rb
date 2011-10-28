class S3

  def self.bucket(bucket_name)
    AWS::S3.new.buckets[bucket_name]
  end

  def self.create_bucket(bucket_name)
    AWS::S3.new.buckets.create(bucket_name)
  end

end
