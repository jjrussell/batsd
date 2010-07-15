class NgmocoDataController < ApplicationController
  include AuthenticationHelper
  
  before_filter 'ngmoco_authenticate'
  
  def index
    return unless verify_params([:date])
    
    partner = Partner.find('4d777c48-db71-48fc-8d75-8afbc511a31c')
    
    start_time = Time.zone.parse(params[:date])
    
    @date = start_time.iso8601[0,10]
    @appstats_list = []
    
    partner.apps.each do |app|
      appstats = Appstats.new(app.id, {
        :start_time => start_time,
        :end_time => start_time + 24.hours})
        
      @appstats_list << [ app, appstats ]
    end
    
    render :template => 'pinger_data/index'
  end
end
