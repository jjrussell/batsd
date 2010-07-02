# TO REMOVE

module PublisherRecordHelper
  include MemcachedHelper
  
  def lookup_by_record(record_id)
    record_id = record_id.gsub("'", '')
    record_key = get_from_cache_and_save("record_id.#{record_id}") do
      user = PublisherUserRecord.select(:where => "record_id = '#{record_id}'")
      if user.items.length == 0
        raise RecordNotFoundException.new("record_id not found: #{record_id}")
      end
      
      record = user.items.first
      record.key
    end
    
    return record_key
  end
  
  def lookup_by_int_record(int_record_id)
    int_record_id = int_record_id.gsub("'", '')
    record_key = get_from_cache_and_save("int_record_id.#{int_record_id}") do
      user = PublisherUserRecord.select(:where => "int_record_id = '#{int_record_id}'")
      if user.items.length == 0
        raise("int_record_id not found: #{int_record_id}")
      end
      
      record = user.items.first
      record.key
    end
    
    return record_key
  end
  
  class RecordNotFoundException < RuntimeError

  end
  
end