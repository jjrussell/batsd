class EpicDataController < ApplicationController
  include AuthenticationHelper
  
  before_filter 'epic_authenticate'
  
  def index
    return unless verify_params([:date])
    
    u = User.find('776fe500-b1ac-4e3b-9367-3e4bd8a4034e')
    
    start_time = Time.zone.parse(params[:date])
    
    @date = start_time.iso8601[0,10]
    @appstats_list = []
    
    u.partners.each do |partner|
      partner.offers.each do |offer|
        appstats = Appstats.new(offer.id, {
          :start_time => start_time,
          :end_time => start_time + 24.hours})
        
        @appstats_list << [ offer, appstats ]        
      end
    end
    
    render 'shared/advertiser_data'
  end
  
end
