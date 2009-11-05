# This module is meant to be mixed in to a SimpledbResource class.
# It is specifically designed to work with SimpleDB, and eventual consistency.
# This module provides methods which allow for an accurate counter to be stored
# even though immediate consistency is not guaranteed.

module Counter
  CONSISTENCY_LIMIT = 0
  
  def increment_count(attr_name)
    # Increments the count by 1, and also deletes uneeded values related to 
    # storing this count.
    
    new_count = get_count(attr_name) + 1
    put(attr_name, create_value(new_count))
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
    #   If increment_count were called, the next value written would be 11,
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
    
    #count_hash, lowest_count, highest_count = get_count_hash(attr_name, get_blacklist(attr_name))
    count_hash, lowest_count, highest_count = get_count_hash(attr_name)
    
    count = get_count_from_hash(count_hash, lowest_count, highest_count)
    new_lowest_count = lowest_count
    for i in lowest_count..highest_count
      if get_count_from_hash(count_hash, lowest_count, highest_count) == count
        new_lowest_count = i
      end
    end
    
    values = []
    get(attr_name).each do |value|
      count, time = parse_value(value)
      if count >= new_lowest_count
        values.push(value)
      end
    end
    put_all(attr_name, values)
  end
  
  private
  
  def get_time_and_pid
    "%.6f.%i" %  [Time.now.to_f, Process.pid]
  end
  
  def create_value(value)
    "#{value}.#{get_time_and_pid}"
  end
  
  def parse_value(value)
    value, epoch, epoch_remainder, pid = value.split('.')
    time = Time.at("#{epoch}.#{epoch_remainder}".to_f)
    count = value.to_i
    return count, time
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
    
    get(attr_name).each do |value|
      count, time = parse_value(value)
      unless blacklist.member?(count)
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
    get(attr_name).each do |value|
      count, time = parse_value(value)
      if now - time < CONSISTENCY_LIMIT
        blacklist.add(count)
      end
    end
    
    return blacklist
  end
end
