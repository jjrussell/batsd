class ZyngaDataController < ApplicationController
  include AuthenticationHelper
  
  before_filter 'zynga_authenticate'
  
  def index
    return unless verify_params([:date])
    
    partner = SdbPartner.new :key => '64e40a83-4724-4ba4-9b38-1c8ca906777a'
    
    start_time = Time.zone.parse(params[:date])
    
    @date = start_time.iso8601[0,10]
    @appstats_list = []
    
    partner.apps.each do |app_pair|
      app_key = app_pair[0].downcase
      
      appstats = Appstats.new(app_key, {
        :start_time => start_time,
        :end_time => start_time + 24.hours})
        
      @appstats_list << appstats
    end
  end
end
