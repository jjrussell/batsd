class S3
  
  def self.reset_connection
    @@s3 = RightAws::S3.new(nil, nil, { :multi_thread => true })
    @@buckets = {}
  end
  
  cattr_reader :s3
  self.reset_connection
  
  def self.bucket(bucket_name, create = false)
    if @@buckets[bucket_name].nil? || @@buckets[bucket_name].full_name != bucket_name
      @@buckets[bucket_name] = @@s3.bucket(bucket_name, false)
    end
    
    if create && @@buckets[bucket_name].nil?
      # Create the bucket on S3 if it does not exist.
      # This is done after the first initialization attempt because, according to the
      # RightAws docs, passing create = true on an existing bucket could modify its ACL.
      @@buckets[bucket_name] = @@s3.bucket(bucket_name, true)
    end
    
    @@buckets[bucket_name]
  end
  
end
