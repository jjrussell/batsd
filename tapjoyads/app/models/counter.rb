# This module is meant to be mixed in to an ActiveResource class.
# It is specifically designed to work with SimpleDB, and eventual consistency.
# This module provides methods which allow for an accurate counter to be stored
# even though immediate consistency is not guaranteed.

module Counter
  SALT = "COUNT"
  CONSISTENCY_LIMIT = 60
  
  def increment_count(attr_name)
    # Increments the count by 1, and also deletes uneeded atributes related to 
    # storing this count.
    
    new_count = get_count(attr_name) + 1
    self.attributes[create_key(attr_name)] = new_count
    delete_uneeded(attr_name)
    return new_count
  end
  
  def get_count(attr_name)
    # Returns the current calculated count.
    # 
    # The equation for calculating the current count is:
    #   highest count + number of duplicate counts - skipped counts
    #   
    #   For example, if the set of reported counts is 4,5,5,5,7,7,8
    #   the count would be 8 + 3 - 1 = 10 
    #   8 is ths highest count found
    #   3 is the number of duplicates (two 5's and one 7)
    #   1 is the number of skips (6 was skipped)
    #   Therefore, get_count would return 10 with the example data set.
    #   The next value that would be written by increment_count would be 11,
    #   making the data set for future reads be 4,5,5,5,6,6,8,11.
    
    count_hash, lowest_count, highest_count = get_count_hash(attr_name)
    
    return get_count_from_hash(count_hash, lowest_count, highest_count)
  end
  
  def delete_uneeded(attr_name)
    # Deletes any attributes that are no longer necessary to calculate the
    # count.
    # This is done by looking at the set of guaranteed consistent attributes
    # (ie, attributes that were written at least 60 seconds ago)
    # and then finding the highest number such that if all numbers below it are
    # deleted, the calculated count would be the same.
    
    count_hash, lowest_count, highest_count = get_count_hash(attr_name, get_blacklist(attr_name))
    
    puts count_hash.to_query
    
    count = get_count_from_hash(count_hash, lowest_count, highest_count)
    new_lowest_count = lowest_count
    for i in lowest_count..highest_count
      if get_count_from_hash(count_hash, lowest_count, highest_count) == count
        new_lowest_count = i
      end
    end
    
    puts "new_lowest_count: #{new_lowest_count}"
    
    keys_to_delete = []
    self.attributes.each do |key, value|
      if is_key_valid(key, attr_name)
        count = value.to_i
        puts "count: #{count}"
        if count < new_lowest_count
          keys_to_delete.push(key)
        end
      end
    end
    
    # keys_to_delete.each do |key|
    #   puts "delete key: #{key}"
    #   self.attributes.delete(key)
    # end
    #SDB.delete_attributes(get_domain_name, attr_name, keys_to_delete)
  end
  
  private
  
  def get_time_and_pid
    "%.6f.%i" %  [Time.now.to_f, Process.pid]
  end
  
  def create_key(attr_name)
    "#{attr_name}.#{SALT}.#{get_time_and_pid}"
  end
  
  def is_key_valid(key, attr_name)
    return key.match("#{attr_name}.#{SALT}")
  end
  
  def parse_key(key)
    attr_name, salt, epoch, epoch_remainder, pid = key.split('.')
    time = Time.at("#{epoch}.#{epoch_remainder}".to_f)
    return time
  end
  
  def get_count_from_hash(count_hash, lowest_count, highest_count)
    offset = 0
    for count in lowest_count..highest_count
      offset += count_hash[count] - 1
    end
    
    return highest_count + offset
  end
  
  def get_count_hash(attr_name, blacklist=Set.new)
    highest_count, lowest_count = 0, 1
    count_hash = Hash.new(0)
    
    self.attributes.each do |key, value|
      if is_key_valid(key, attr_name) && !blacklist.member?(value)
        count = value.to_i
        count_hash[count] += 1

        lowest_count = highest_count == 0 || count < lowest_count ? count : lowest_count
        highest_count = count > highest_count ? count : highest_count
      end
    end
    return count_hash, lowest_count, highest_count
  end
  
  def get_blacklist(attr_name)
    blacklist = Set.new
    now = Time.now
    self.attributes.each do |key, value|
      if is_key_valid(key, attr_name)
        count = value.to_i
        time = parse_key(key)
        if now - time < CONSISTENCY_LIMIT
          blacklist.add(count)
        end
      end
    end
    
    return blacklist
  end
  
  def get_domain_name
    return self.prefix[1..-2]
  end
end
