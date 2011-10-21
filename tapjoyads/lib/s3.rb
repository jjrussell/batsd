class S3

  def self.bucket(bucket_name, create = false)
    s3 = RightAws::S3.new(nil, nil, { :multi_thread => true, :port => 80, :protocol => 'http' })
    if create
      bucket = s3.bucket(bucket_name, false)
      bucket = s3.bucket(bucket_name, true) if bucket.nil?
    else
      bucket = RightAws::S3::Bucket.new(s3, bucket_name)
    end
    bucket
  end

end
