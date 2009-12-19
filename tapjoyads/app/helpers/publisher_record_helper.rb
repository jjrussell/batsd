module PublisherRecordHelper
  include MemcachedHelper
  
  def lookup_by_record(record_id)
    record = get_from_cache_and_save("record_id.#{record_id}") do
      user = SimpledbResource.select('publisher-user-record','*', "record_id = '#{record_id}'")
      if user.items.length == 0
        raise("record_id not found: #{record_id}")
      end
      
      record = user.items.first
      record.key
    end
  end
  
  def lookup_by_int_record(int_record_id)
    record = get_from_cache_and_save("record_id.#{record_id}") do
      user = SimpledbResource.select('publisher-user-record','*', "int_record_id = '#{int_record_id}'")
      if user.items.length == 0
        raise("int_record_id not found: #{int_record_id}")
      end
      
      record = user.items.first
      record.key
    end
  end
  
end