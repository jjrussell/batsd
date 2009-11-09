class AdshownRequestProcessor < ApplicationProcessor

  subscribes_to :update_stats
  
  #this updates the stats for the item for the proposed date
  def on_message(item_id, item_type, date)
    logger.debug "Update Stats request received: " + message
      
    #get the current stat row for this item
    key = "#{item_type}.#{date}.#{item_id}"
    
    #if it doesn't exist, create it
    stat = Stats.new(key)
    
    #go through each hour and update the count for that hour
    for hour in 0..23 do
      #find the hour to update, look at 000000 usec for that next hour
      parts = date.split('-')
      year = parts[0]
      month = parts[1]
      day = parts[2]
      hr = "%02d" % hour
      usec = '000001'
      
      beginning_timestamp = "#{year}#{month}#{day}#{hr}#{usec}"
      
      hr = "%02d" % hour + 1
      usec = '000000'
      
      end_timestamp = "#{year}#{month}#{day}#{hr}#{usec}"
      
      #count = select count(*) from WebRequests where type = impressions and 
      # key = item_type.item_id and date = date and
      # timestamp between beginning_timestamp and end_timestamp
      
      stat.put('h#{hr}.impressions', count)      
    end      
      
    #set the visibility timeout for this message based on whether or not that Save succeeded
     
    #for old days, set the visibility timeout for longer periods of time
    
    #after 7 days, delete the entry from the queue entirely
    logger.info "Stats updated for #{item_type}: #{item_id}"
  end
end