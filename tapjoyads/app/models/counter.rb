# This module is meant to be mixed in to a SimpledbResource class.
# It is specifically designed to work with SimpleDB, and eventual consistency.
# This module provides methods which allow for an accurate counter to be stored
# even though immediate consistency is not guaranteed.
#
# This works by always putting new attributes, rather than overwriting.
# The count is then always calculated from the set of attributes.
# Attributes are only deleted once they are older than a certain time, and no
# longer needed for the count calculations.
#
# The equation for calculating the current count of a single row is:
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
#
# The count may also be distributed across multiple rows. This is necessary due to
# the fact that the count may have been incremented more than 256 times in the last 60 seconds.

require 'socket'

class Counter < SimpledbResource
  CONSISTENCY_LIMIT = 60
  MAX_ATTRS = 200
  DISTRIBUTED_ATTR = 'DISTRIBUTED_COUNT' # Name of attribute which indicates that a row's count is distributed.
  
  ##
  # Increments the count by 1, and also deletes uneeded values related to 
  # storing this count.
  def increment_count(attr_name, options = {})
    use_memcache = options.delete(:use_memcache) { true }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
    # TODO: Increment count in memcache
    
    delete_uneeded(attr_name)
    
    if get_num_attrs > MAX_ATTRS
      put(DISTRIBUTED_ATTR, '1')
      get_next_row.increment_count(attr_name)
    else
      new_count = get_count(attr_name, {:this_row_only => true}) + 1
      put(attr_name, create_value(new_count), {:replace => false})
    end
  end
  
  ##
  # Returns the current calculated count.
  def get_count(attr_name, options = {})
    this_row_only = options.delete(:this_row_only) { false }
    use_memcache = options.delete(:use_memcache) { true }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    # TODO: First, try to get count from memcache. If not found in mc, calculate the count from sdb.
    
    count_hash, lowest_count, highest_count = get_count_hash(attr_name)
    
    distributed_count = 0
    if not this_row_only and get(DISTRIBUTED_ATTR) == '1'
      next_row = get_next_row
      if next_row
        distributed_count = next_row.get_count(attr_name)
      end
    end

    count = get_count_from_hash(count_hash, lowest_count, highest_count) 

    # TODO: Store count to mc

    return count + distributed_count
  end
  
  ##
  # Deletes any attributes that are no longer necessary to calculate the
  # count. Only operates on this row, not distributed rows.
  # This is done by looking at the set of guaranteed consistent attributes
  # (ie, attributes that were written at least 60 seconds ago)
  # and then finding the highest number such that if all numbers below it are
  # deleted, the calculated count would be the same.
  def delete_uneeded(attr_name)
    count_hash, lowest_count, highest_count = get_count_hash(attr_name, get_blacklist(attr_name))
    
    Rails.logger.info "Delete uneeded: blacklist hash: #{count_hash.to_json}"
    
    count = get_count_from_hash(count_hash, lowest_count, highest_count)
    new_lowest_count = lowest_count
    for i in lowest_count..highest_count
      if get_count_from_hash(count_hash, i, highest_count) == count
        new_lowest_count = i
      end
    end
    
    Rails.logger.info "Delete uneeded: new_lowest_count: #{new_lowest_count}"
    
    values_to_delete = []
    get(attr_name, {:force_array => true}).each do |value|
      count, time = parse_value(value)
      if count < new_lowest_count
        values_to_delete.push(value)
      end
    end
    
    values_to_delete.each do |value|
      delete(attr_name, value)
    end
  end
  
  def save
    super({:replace => false, :write_to_memcache => false, :updated_at => false})
    if @next_row
      @next_row.save
    end
  end
  
  ##
  # Never load from memcache.
  # TODO: clever loading from memcache. Load all distributed rows as well.
  def load(not_used)
    super(false)
  end
  
  ##
  # Deletes this row, as well as all distribued rows. If this row hasn't been loaded, then
  # distributed rows will not be searched for.
  def delete_all
    if @next_row
      @next_row.delete_all
    end
    super
  end
  
  private
  
  ##
  # Gets the current time.
  def get_time
    "%.6f" %  Time.now.utc.to_f
  end
  
  ##
  # Returns a unique process identifier - even accross distrbuted machines.
  # Including this in the value ensures that even if two timestamps in different
  # processes are identical, values will still not be overwritten.
  def get_pid
    (Process.pid.to_s + Socket.gethostname).hash
  end
  
  ##
  # Creates a value given a count.
  def create_value(count)
    "#{count}.#{get_time}.#{get_pid}"
  end
  
  ##
  # Returns the count and the time for a given value.
  def parse_value(value)
    value, epoch, epoch_remainder, pid = value.split('.')
    time = Time.at("#{epoch}.#{epoch_remainder}".to_f)
    count = value.to_i
    return count, time
  end
  
  ##
  # Calculates the count from a hash of counts, using the formula:
  # highest_count + duplicate counts - skipped counts
  def get_count_from_hash(count_hash, lowest_count, highest_count)
    offset = 0
    for count in lowest_count..highest_count
      offset += count_hash[count] - 1
    end
    
    return highest_count + offset
  end
  
  ##
  # Returns a hash of all counts associated with this attribute. The key is the count,
  # and the values is the number of times the count occured.
  # For example, if the set of reported counts is 4,5,5,5,7,7,8
  # then the hash will be:  {4 => 1, 5 => 3, 7 => 2, 8 => 1}
  # The has has a default value of 0.
  def get_count_hash(attr_name, blacklist=Set.new)
    highest_count, lowest_count = 0, 1
    count_hash = Hash.new(0)
    
    get(attr_name, {:force_array => true}).each do |value|
      count, time = parse_value(value)
      unless blacklist.member?(count)
        count_hash[count] += 1
      
        lowest_count = highest_count == 0 || count < lowest_count ? count : lowest_count
        highest_count = count > highest_count ? count : highest_count
      end
    end
    return count_hash, lowest_count, highest_count
  end
  
  ##
  # Returns an array of blacklist values for a given attributes.
  # An value is placed in the blacklist if it is too recent to be guaranteed consistent.
  def get_blacklist(attr_name)
    blacklist = Set.new
    now = Time.now.utc
    get(attr_name, {:force_array => true}).each do |value|
      count, time = parse_value(value)
      if now - time < CONSISTENCY_LIMIT
        blacklist.add(count)
      end
    end
    
    return blacklist
  end
  
  ##
  # Returns the total number of attributes being stored in this row.
  def get_num_attrs
    total = 0
    attributes.each_value do |value|
      total += value.length
    end
    return total
  end
  
  ##
  # Returns the next distributed row which stores counts. This row is used if the frequency of
  # increments is too great.
  def get_next_row
    unless @next_row
      @next_row = Counter.new(@domain_name, get_next_row_name)
    end
    return @next_row
  end
  
  def get_next_row_name
    match = @key.match(/^(.*)-count(\d*)$/)
    if match
      return match[1] + "-count#{match[2].to_i + 1}"
    end
    return @key + '-count1'
  end
end
