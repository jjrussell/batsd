class FluentDataController < ApplicationController
  include AuthenticationHelper
  
  before_filter 'fluent_authenticate'
  
  def index
    return unless verify_params([:date])
    
    partner = Partner.find('1faa4e38-e118-4249-88f7-258d16ab24cf')
    extra_apps = [ '91647185-9af5-4da8-80e6-6e66479837f9', '2cf8e550-2dab-432a-b5bb-87c0c7afb5f0', '856f074c-d284-449e-8d2d-f7ef85f257a7' ]
    
    start_time = Time.zone.parse(params[:date])
    
    @date = start_time.iso8601[0,10]
    @appstats_list = []
    
    (partner.apps + App.find(extra_apps)).each do |app|
      appstats = Appstats.new(app.id, {
        :start_time => start_time,
        :end_time => start_time + 24.hours})
        
      @appstats_list << [ app, appstats ]
    end
  end
end
