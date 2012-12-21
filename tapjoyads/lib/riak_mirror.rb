module RiakMirror
  def self.included(base)
    base.send :extend, ClassMethods
    base.send :alias_method, :write_to_sdb_without_mirror, :write_to_sdb
    base.send :alias_method, :write_to_sdb, :write_to_sdb_with_mirror
    base.send :alias_method, :load_from_sdb_without_mirror, :load_from_sdb
    base.send :alias_method, :load_from_sdb, :load_from_sdb_with_mirror
  end

  #Override the write to SDB functionality so that we also mirror all writes to
  #riak for redundancy.  We're always going to write the full object to Riak, so
  #there are no partial updates.  Whatever the state of the attributes is at write time
  #is what we put into riak
  def write_to_sdb_with_mirror(expected_attr = {})
    result = self.disable_sdb_writes ? {} : write_to_sdb_without_mirror(expected_attr)

    retry_count = 0
    begin
      json = @attributes.to_json
      indexes = {}
      self.secondary_indexes.each do |attribute_name|
        indexes["#{attribute_name}_bin"] = [@attributes[attribute_name]] unless @attributes[attribute_name].blank?
      end
      RiakWrapper.put(self.riak_bucket_name, @key, json, indexes)
    rescue Exception => e
      retry_count += 1
      retry if retry_count < 4
      Rails.logger.error "Error writing to Riak"
      #Let's catch all Riak exceptions.  We don't want these to bubble up.  I'll fire
      #off an Airbrake message just so I know what's going on
      Airbrake.notify_or_ignore(e)
    end

    #And now it's like we were never here...
    result
  end

  def load_from_sdb_with_mirror(consistent=false)
    if read_from_riak && !@bypass_riak_reads
      retry_count = 0
      begin
        RiakWrapper.get_json(self.riak_bucket_name, @key)
      rescue Exception => e
        retry_count += 1
        retry if retry_count < 4
        Rails.logger.error "Error reading from Riak"
        Airbrake.notify_or_ignore(e)
        #Fallback to SDB
        load_from_sdb_without_mirror(consistent)  
      end
    else
      load_from_sdb_without_mirror(consistent)
    end
  end

  module ClassMethods
    def mirror_configuration(options = {})
      cattr_accessor :riak_bucket_name
      cattr_accessor :read_from_riak
      cattr_accessor :secondary_indexes
      cattr_accessor :disable_sdb_writes
      self.riak_bucket_name = options[:riak_bucket_name]
      self.read_from_riak = options[:read_from_riak] || false
      self.secondary_indexes = [options[:secondary_indexes]].flatten || []
      self.disable_sdb_writes = options[:disable_sdb_writes] || false
    end
  end
end
