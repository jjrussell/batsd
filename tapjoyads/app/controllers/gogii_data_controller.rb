class GogiiDataController < ApplicationController
  include AuthenticationHelper
  
  before_filter 'gogii_authenticate'
  
  def index
    return unless verify_params([:date])
    
    partner = Partner.find('742f128d-accd-41af-b9d6-4be5d402af85')
    
    start_time = Time.zone.parse(params[:date])
    
    @date = start_time.iso8601[0,10]
    @appstats_list = []
    
    partner.apps.each do |app|
      appstats = Appstats.new(app.id, {
        :start_time => start_time,
        :end_time => start_time + 24.hours})
        
      @appstats_list << [ app, appstats ]
    end
    
    render :template => 'fluent_data/index'
  end
end
