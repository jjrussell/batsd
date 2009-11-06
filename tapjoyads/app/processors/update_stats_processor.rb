class AdshownRequestProcessor < ApplicationProcessor

  subscribes_to :update_stats
  
  def on_message(item_id, item_type)
    logger.debug "Update Stats request received: " + message
      
    #get the current stat row for this item
    date = time.iso8601[0,10]
    key = "#{item_type}.#{date}.#{item_id}"
    stat = Stats.find(:first, key)
    stat = Stats.new()
    
    #if it doesn't exist, create it
    
    #go back one minute, and count all impressions since the LastUpdated timestamp
    
    #set our new total impressions and new timestamp based 
    
    #set the visibility timeout for this message based on whether or not that Save succeeded
    
    logger.info "Stats updated for #{item_type}: #{item_id}"
  end
end