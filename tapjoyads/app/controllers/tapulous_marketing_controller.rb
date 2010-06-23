class TapulousMarketingController < ApplicationController
  include AuthenticationHelper
  
  before_filter 'tapulous_authenticate'
  
  def index
    return unless verify_params([:date])
    
    app_key= 'e2479a17-ce5e-45b3-95be-6f24d2c85c6f'

    start_time = Time.zone.parse(params[:date])
    
    appstats = Appstats.new(app_key, {
      :start_time => start_time,
      :end_time => start_time + 24.hours})
    
    paidstats = Appstats.new('5597b9ab-8da0-4f17-8430-4e20e8d9e191', { 
      :start_time => start_time, 
      :end_time => start_time + 24.hours})  
      
    @date = start_time.iso8601[0,10]
    @paid_installs = paidstats.stats['paid_installs'].sum
    @spend = paidstats.stats['installs_spend'].sum
    @revenue = appstats.stats['installs_revenue'].sum
    @published_installs = appstats.stats['published_installs'].sum
  end
  
end