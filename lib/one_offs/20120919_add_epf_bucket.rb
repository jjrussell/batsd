class OneOffs
  def self.add_epf_bucket
    S3.create_bucket(BucketNames::APPLE_EPF)
  end
end
