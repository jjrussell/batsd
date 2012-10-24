module RiakMirror
  def self.included(base)
    base.send :extend, ClassMethods
    base.send :alias_method, :write_to_sdb_without_mirror, :write_to_sdb
    base.send :alias_method, :write_to_sdb, :write_to_sdb_with_mirror
  end

  #Override the write to SDB functionality so that we also mirror all writes to 
  #riak for redundancy.  We're always going to write the full object to Riak, so
  #there are no partial updates.  Whatever the state of the attributes is at write time
  #is what we put into riak
  def write_to_sdb_with_mirror(expected_attr = {})    
    result = write_to_sdb_without_mirror(expected_attr)

    begin
      json = @attributes.to_json
      RiakWrapper.put(self.riak_bucket_name, @key, json)
    rescue Exception => e
      Rails.logger.error "Error writing to Riak"
      #Let's catch all Riak exceptions.  We don't want these to bubble up.  I'll fire
      #off an Airbrake message just so I know what's going on
      Airbrake.notify_or_ignore(e)
    end

    #And now it's like we were never here...
    result
  end

  module ClassMethods
    def mirror_configuration(options = {})
      cattr_accessor :riak_bucket_name
      self.riak_bucket_name = options[:riak_bucket_name]
    end
  end
end