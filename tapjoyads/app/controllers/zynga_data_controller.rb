class ZyngaDataController < ApplicationController
  include AuthenticationHelper
  
  before_filter 'zynga_authenticate'
  
  def index
    return unless verify_params([:date])
    
    partner = Partner.find('64e40a83-4724-4ba4-9b38-1c8ca906777a')
    
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
