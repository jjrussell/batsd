class PublisherUserRecord < SimpledbResource
  include MemcachedHelper
  
  self.domain_name = 'publisher-user-record'
  
  ##
  # Creates and saves a new record_id and int_record_id for this record, if they don't already exist.
  # Since this method may be called simultaneously by different processes, the replace 
  # option is set to false for record_id and int_record_id.
  def update(device_id)
    unless get('record_id') and get('int_record_id') and get('udid')
      guid = UUIDTools::UUID.random_create.to_s
      put('record_id',  guid, {:replace => false})
      put('int_record_id', guid.hash.abs.to_s, {:replace => false})
      put('udid', device_id)
      save
      save_to_cache("record_id.#{get('record_id')}", @key)
      save_to_cache("int_record_id.#{get('int_record_id')}", @key)
    end
  end
  
  ##
  # Returns the first record_id.
  def get_record_id
    get('record_id', :force_array => true)[0]
  end
  
  ##
  # Returns the first int_record_id.
  def get_int_record_id
    get('int_record_id', :force_array => true)[0]
  end
end