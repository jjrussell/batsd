class FluentDataController < ApplicationController
  include AuthenticationHelper
  
  before_filter 'fluent_authenticate'
  
  def index
    return unless verify_params([:date])
    
    partner = Partner.find('1faa4e38-e118-4249-88f7-258d16ab24cf')
    
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
