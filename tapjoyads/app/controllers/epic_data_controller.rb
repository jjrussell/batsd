class EpicDataController < ApplicationController
  include AuthenticationHelper
  
  before_filter 'epic_authenticate'
  
  def index
    return unless verify_params([:date])
    
    u = User.find('65b41712-4a5c-4eb9-8e54-db472a56ad58')
    
    start_time = Time.zone.parse(params[:date])
    
    @date = start_time.iso8601[0,10]
    @appstats_list = []
    
    u.partners.each do |partner|
      partner.offers.each do |app|
        appstats = Appstats.new(app.id, {
          :start_time => start_time,
          :end_time => start_time + 24.hours})
        
        @appstats_list << [ app, appstats ]        
      end
    end
      
  end
  
end
