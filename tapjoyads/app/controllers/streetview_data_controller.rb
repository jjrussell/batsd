class StreetviewDataController < ApplicationController
  include AuthenticationHelper
  
  before_filter 'streetview_authenticate'
  
  def index
    return unless verify_params([:date])
    
    partner = SdbPartner.new :key => '9827ebca-d1ad-4dea-b61b-f38dd0d298c1'
    
    start_time = Time.zone.parse(params[:date])
    
    # PST:
    start_time = start_time + 8.hours
    
    @date = (start_time + 1.day).iso8601[0,10] + ' PST'
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