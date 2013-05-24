module SdbMigrator

  def self.included(base)
    base.send :extend, ClassMethods
    base.send :alias_method, :write_to_sdb_without_mirror, :write_to_sdb
    base.send :alias_method, :write_to_sdb, :write_to_sdb_with_mirror
    #base.send :alias_method, :load_without_mirror, :load
    #base.send :alias_method, :load, :load_with_mirror
  end

  #Unused at this point.  Can be used if we want to load with fault tolerance
  # def load_with_mirror(load_from_memcache = true, consistent = false)
  #   result = nil
  #   #First try to load from the current sdb domain
  #   result = load_without_mirror(load_from_memcache, consistent)
  #   if @attributes.empty?
  #     #Current SDB domain doesn't have what we're looking for, so check the new domain
  #     current_name = @this_domain_name
  #     @this_domain_name = self.new_dynamic_domain_name
  #     result = load_without_mirror(load_from_memcache, consistent)
  #     @this_domain_name = current_name
  #     unless @attributes.empty?
  #       #We looked it up in the new cache and found it, so if we save it, we want to persist to
  #       #the old cache with all the attribute, so we trick the simpledb_resource
  #       #class into saving all the attrs
  #       @attributes_to_add = @attributes.clone
  #     end
  #   end
  #   result
  # end

  #Override the write to sdb process so that we actually write it to two different
  #places.  This will keep the two domains in sync as we migrate over.  When we run
  #the migration script, we will skip over any pre-existing keys in the new domain
  #and assume we're up to date
  def write_to_sdb_with_mirror(expected_attr = {})
    #Try to write to the current domain, note that this call will error out with some frequency
    #We'll just go ahead and pass that error back up the call chain
    old_attributes = @attributes
    old_attributes_to_add = @attributes_to_add.clone
    old_attributes_to_replace = @attributes_to_replace.clone
    old_attributes_to_delete = @attributes_to_delete.clone

    result = write_to_sdb_without_mirror(expected_attr)
    #If we're here, we didn't error out, it's time to try to write to the new domain

    retry_count = 0
    begin

      #We're going to need to clone the attributes over to the mirror, so keep this for backup
      @attributes_to_add = old_attributes.merge(old_attributes_to_add)
      @attributes_to_delete = old_attributes_to_delete
      #Keep track of the current domain
      current_name = @this_domain_name

      #Get the "new" domain
      @this_domain_name = self.new_dynamic_domain_name
      write_to_sdb_without_mirror(expected_attr)
    rescue Exception => e
      #Retry since we do error out frequently
      if retry_count < 4
        retry_count += 1
        retry
      end

      #Failed mirror call... Let's keep track of all these failures,
      #and we'll go back and manually fix it
      uuid = UUIDTools::UUID.random_create.to_s
      bucket = S3.bucket(BucketNames::FAILED_SDB_SAVES)
      bucket.objects["failed_mirror/#{uuid}"].write(:data => self.serialize)
    ensure
      #Switch back to the current name & old attributes to add
      @this_domain_name = current_name
      @attributes_to_add = old_attributes_to_add
      @attributes_to_replace = old_attributes_to_replace
      @attributes_to_delete = old_attributes_to_delete
    end

    #And now it's like we were never here...
    result
  end

  module ClassMethods
    def new_configuration(options = {})
      cattr_accessor :new_domain_name, :new_num_domains
      self.new_domain_name = options[:new_domain_name]
      self.new_num_domains = options[:new_num_domains]
    end
  end

  protected
    def new_dynamic_domain_name
      domain_number = @key.matz_silly_hash % self.new_num_domains
      "#{self.new_domain_name}_#{domain_number}"
    end

end
