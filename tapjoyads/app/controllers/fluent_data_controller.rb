class FluentDataController < ApplicationController
  include AuthenticationHelper
  
  before_filter 'fluent_authenticate'
  
  def index
    return unless verify_params([:date])
    
    partner = Partner.find('1faa4e38-e118-4249-88f7-258d16ab24cf')
    extra_apps = [ '91647185-9af5-4da8-80e6-6e66479837f9', '2cf8e550-2dab-432a-b5bb-87c0c7afb5f0', '856f074c-d284-449e-8d2d-f7ef85f257a7', 
      '917b59ea-1d45-43e3-8a2f-9b1d1f0e142e', '192e6d0b-cc2f-44c2-957c-9481e3c223a0', '7baa7e9d-6d06-46f8-9909-162312a867de', 
      'dfb4c57b-c156-4733-b53f-c99161ce4dd1', '92572adf-2cf4-4af6-a293-7715ae0508ff', 'a3f3bf6c-3e9e-4bbe-98ac-6b43d0e3814f', '7591b5ef-4b11-41b8-aed6-c69ecde86503',
      'dae95712-0d9c-44a4-82d5-c73686726f44', 'b0388e2c-dbb5-49f6-8c90-a08d857016a4', '51e42b6c-5393-432d-b058-b9dd10e14a9c', '3edd25b7-0aaa-4f71-be6d-5ec621c86c74',
      '3e75f700-33fe-4cbd-bf1e-ac84de56605e', '6466e256-2a0e-4b32-b001-859398274856' ]
    
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
