module RiakWrapper

  #A wrapper around retrieving an object from riak
  def self.get(bucket, key)
    begin
      $riak[bucket][key].raw_data
    rescue Exception => e
      #We couldn't retrieve from Riak... We could try an exists? here to double check
      #that it is indeed not found, due to the read-repair issue
      $riak[bucket].exists?(key) ? $riak[bucket][key].raw_data : nil
    end
  end

  #Same as get, but tries to parse the object into JSON
  def self.get_json(bucket, key)
    json = self.get(bucket, key)
    #If we didn't get anything back from riak, return an empty hash, otherwise parse the JSON
    json.nil? ? {} : JSON.parse(json)
  end

  #Just a wrapper around storing an object in riak
  def self.put(bucket_name, key, value, secondary_indexes={}, content_type='application/json')
    bucket = $riak.bucket(bucket_name)
    object = bucket.get_or_new(key)
    object.content_type = content_type
    object.indexes = secondary_indexes
    object.raw_data = value
    object.store

    # Write devices to two riak clusters..sdb is about to lose it.
    #SUPER HACKY.  Obviously we could abstract this change, but I'd rather isolate the code we know is working
    if bucket_name == 'd'
      device_bucket = $riak_devices.bucket(bucket_name)
      device_object = device_bucket.get_or_new(key)
      device_object.content_type = content_type
      device_object.indexes = secondary_indexes
      device_object.raw_data = value
      device_object.store
    end
  end

end
