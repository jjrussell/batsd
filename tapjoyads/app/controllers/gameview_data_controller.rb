class GameviewDataController < ApplicationController
  include AuthenticationHelper
  
  before_filter 'gameview_authenticate'
  
  def index
    return unless verify_params([:date])
    
    partner = Partner.find('e9a6d51c-cef9-4ee4-a2c9-51eef1989c4e')
    
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
