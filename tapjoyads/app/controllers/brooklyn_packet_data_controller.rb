class BrooklynPacketDataController < ApplicationController
  include AuthenticationHelper
  
  before_filter 'brooklyn_packet_authenticate'
  
  def index
    return unless verify_params([:date])
    
    partner = Partner.find('c517b19e-fc75-4ab2-974e-e493b7ab33ab')
    
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
