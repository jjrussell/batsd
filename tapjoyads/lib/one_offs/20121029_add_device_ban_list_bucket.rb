class OneOffs
  def self.add_device_ban_list_bucket
    S3.create_bucket(BucketNames::DEVICE_BAN_LIST)
  end
end
