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
  def self.put(bucket, key, value, secondary_indexes={}, content_type='application/json')
    bucket = $riak.bucket(bucket)
    object = bucket.get_or_new(key)
    object.content_type = content_type
    object.indexes = secondary_indexes
    object.raw_data = value
    object.store
  end

end
