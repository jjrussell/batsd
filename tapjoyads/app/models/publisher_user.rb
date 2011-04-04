class PublisherUser < SimpledbShardedResource
  MAX_UDIDS = 5
  
  self.num_domains = NUM_PUBLISHER_USER_DOMAINS
  
  self.sdb_attr :udids, :force_array => true, :replace => false
  
  def dynamic_domain_name
    domain_number = @key.hash % NUM_PUBLISHER_USER_DOMAINS
    "publisher_users_#{domain_number}"
  end
  
  def update!(udid)
    return false if udids.length >= MAX_UDIDS
    return true  if udids.include?(udid)
    
    self.udids = udid
    serial_save
    
    udids.length < MAX_UDIDS
  end
  
  # TO REMOVE - once the one-off finishes
  def self.find_or_initialize(key)
    pub_user = self.new(:key => key)
    return pub_user unless pub_user.new_record?
    
    pub_user_record = PublisherUserRecord.new(:key => key)
    return pub_user if pub_user_record.new_record?
    
    pub_user_record.get('udid', :force_array => true).each do |udid|
      pub_user.udids = udid
    end
    pub_user
  end
  
end
