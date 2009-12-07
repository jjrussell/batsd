class RateAppOfferController < ApplicationController
  include RightAws
  
  def index
    record_id = params[:record_id]
    udid = params[:udid]
    app_id = params[:app_id]
    
    app = App.new(app_id)
    
    message = {:udid => udid, :app_id => app_id, 
          :record_id => record_id}.to_json
    SqsGen2.new.queue(QueueNames::RATE_OFFER).send_message(message)
    
    redirect_to app.get('store_url')
   
  end
  
  
end
