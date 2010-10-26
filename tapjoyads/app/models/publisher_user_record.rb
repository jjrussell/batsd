class PublisherUserRecord < SimpledbResource
  
  self.domain_name = 'publisher-user-record'
  
  def update(device_id)
    udids = get('udid', :force_array => true)
    if udids.length < 5
      put('udid', device_id, :replace => false)
      save if changed?
      return true
    else
      return false
    end
  end
  
end
