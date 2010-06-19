class PingerDataController < ApplicationController
  include AuthenticationHelper
  
  before_filter 'pinger_authenticate'
  
  def index
    return unless verify_params([:date])
    
    partner = Partner.find('443721a9-e426-47de-948c-658a558744bc')
    
    start_time = Time.zone.parse(params[:date])
    
    @date = start_time.iso8601[0,10]
    @appstats_list = []
    
    partner.apps.each do |app|
      appstats = Appstats.new(app.id, {
        :start_time => start_time,
        :end_time => start_time + 24.hours})
        
      @appstats_list << [ app, appstats ]
    end
  end
end
