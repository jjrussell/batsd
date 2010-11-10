class SgnDataController < ApplicationController
  include AuthenticationHelper
  
  before_filter 'sgn_authenticate'
  
  def index
    return unless verify_params([:date])
    
    partner = Partner.find('fcc32769-5fb1-41a0-b7dc-960842eae332')
    
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
