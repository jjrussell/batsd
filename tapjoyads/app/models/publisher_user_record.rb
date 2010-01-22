class PublisherUserRecord < SimpledbResource
  include MemcachedHelper
  
  self.domain_name = 'publisher-user-record'
  
  ##
  # Creates and saves a new record_id and int_record_id for this record, if they don't already exist.
  def update(device_id)
    unless get('record_id') and get('int_record_id') and get('udid')
      uuid = UUIDTools::UUID.random_create.to_s
      put('record_id',  uuid, {:replace => false})
      put('int_record_id', uuid.hash.abs.to_s, {:replace => false})
      put('udid', device_id)
      save
      save_to_cache("record_id.#{get('record_id')}", @key)
      save_to_cache("int_record_id.#{get('int_record_id')}", @key)
    end
  end
end