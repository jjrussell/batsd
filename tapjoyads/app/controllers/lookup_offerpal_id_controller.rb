class LookupOfferpalIdController < ApplicationController
  
  missing_message = "missing required params"
  verify :params => [:int_id],
         :render => {:text => missing_message}

         
  def index
    int_id = params[:int_id]
    user = SimpledbResource.select('publisher-user-record','*', "int_record_id = '#{int_id}'")
    record = user.items.first
    
    render :text => record.key #this contains the app_id.pubisher_user_id

  end         
  
end
