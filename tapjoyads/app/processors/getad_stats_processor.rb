require 'cgi'

class GetadStatsProcessor < ApplicationProcessor

  subscribes_to :getad_stats

  def on_message(message)
    logger.debug "GetadStatsProcessor received: " + message
    stats = GetadStats.deserialize(message)
    
    app = App.new(stats.app_id)
    app.increment_count('request')
    app.increment_count('returned') if stats.ad_returned
    app.save
    logger.info "App stats stored. Simpledb box usage: #{app.box_usage}"
  end
end