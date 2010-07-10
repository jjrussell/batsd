class PublisherUserRecord < SimpledbResource
  
  self.domain_name = 'publisher-user-record'
  
  def self.lookup_key_by_int_record_id(int_record_id)
    int_record_id.gsub!("'", '')
    # using App.new to get a reference to memcached helper. fix when memcached helper becomes a lib
    record_key = Mc.get_and_put("int_record_id.#{int_record_id}") do
      result = PublisherUserRecord.select(:where => "int_record_id = '#{int_record_id}'")
      if result[:items].length == 0
        raise("int_record_id not found: #{int_record_id}")
      end
      
      record = result[:items].first
      record.key
    end
    
    return record_key
  end
  
  def self.generate_int_record_id(app_id, user_id)
    "#{app_id}.#{user_id}".hash.abs.to_s
  end
  
  def update(device_id)
    new_int_record_id = @key.hash.abs.to_s
    unless get('int_record_id') == new_int_record_id
      put('int_record_id', new_int_record_id)
      Mc.put("int_record_id.#{new_int_record_id}", @key)
    end
    
    udids = get('udid', :force_array => true)
    if udids.length > 5
      return false
    else
      put('udid', device_id, :replace => false)
      save if changed?
      return true
    end
  end
  
end
