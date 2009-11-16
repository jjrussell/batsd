class GetadStatsProcessor < ApplicationProcessor

  subscribes_to :getad_stats
  
  def message(app_id, is_ad_returned)
    app = App.new(app_id)
    app.increment_count('request')
    app.increment_count('returned') if is_ad_returned == '1'
    app.save
    logger.info "App stats stored. Simpledb box usage: #{app.box_usage}"
  end
  
  def log(message)
    logger.debug "GetadStatsProcessor received: " + message
  end
  
end