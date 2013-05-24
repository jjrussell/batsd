require 'riak_wrapper'

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
    result = {}
    #Till we get in a test riak solution, we can keep using mock sdb
    if !self.disable_sdb_writes || !Rails.env.production?
      result = write_to_sdb_without_mirror(expected_attr)
    end

    retry_count = 0
    json = @attributes.to_json
    indexes = {}
    self.secondary_indexes.each do |attribute_name|
      indexes["#{attribute_name}_bin"] = [@attributes[attribute_name]] unless @attributes[attribute_name].blank?
    end
    begin
      RiakWrapper.put(self.riak_bucket_name, @key, json, indexes)
    rescue Exception => e
      retry_count += 1
      retry if retry_count < 4
      Rails.logger.error "Error writing to Riak"
      #Let's catch all Riak exceptions.  We don't want these to bubble up.  I'll fire
      #off an Airbrake message just so I know what's going on
      Airbrake.notify_or_ignore(e)
      #Disable queueing for tests until we get the test Riak in palce
      if self.queue_failed_writes && Rails.env.production?
        #Push the data off to the riak write queue
        Rails.logger.info "Riak save failed. Adding to sqs. Domain: #{self.riak_bucket_name} Key: #{@key} Exception: #{e.class} - #{e}"
        uuid = UUIDTools::UUID.random_create.to_s
        s3_bucket = S3.bucket(BucketNames::FAILED_RIAK_SAVES)
        riak_data = {
          :json_data => json,
          :bucket_name => self.riak_bucket_name,
          :key => @key,
          :indexes => indexes
        }
        s3_bucket.objects["incomplete/#{uuid}"].write(:data => riak_data.to_json)
        message = { :uuid => uuid }.to_json
        Sqs.send_message(QueueNames::FAILED_RIAK_SAVES, message)
        Rails.logger.info "Successfully added to sqs. Message: #{message}"
      end
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
        #If we don't have the data in SDB, no need to fallback to it
        if self.disable_sdb_writes && Rails.env.production?
          raise e
        else
          #Fallback to SDB
          load_from_sdb_without_mirror(consistent)
        end
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
      cattr_accessor :queue_failed_writes
      self.riak_bucket_name = options[:riak_bucket_name]
      self.read_from_riak = options[:read_from_riak] || false
      self.secondary_indexes = [options[:secondary_indexes]].flatten || []
      self.disable_sdb_writes = options[:disable_sdb_writes] || false
      self.queue_failed_writes = options[:queue_failed_writes] || false
    end
  end
end
