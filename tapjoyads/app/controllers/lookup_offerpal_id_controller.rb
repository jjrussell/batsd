class LookupOfferpalIdController < ApplicationController
  
  missing_message = "missing required params"
  verify :params => [:int_id],
         :render => {:text => missing_message}

         
  def index
    int_id = params[:int_id]
    user = SimpledbResource.select('publisher-user-record','*', "int_record_id = '#{int_id}'")
    record = user.items.first
    
    if record
      render :text => record.key  #this contains app_id.publisher_user_id
    else
      render :text => "not_found"
    end
    
  end         

  def reverse
    record_id = params[:record_id]
    user = SimpledbResource.select('publisher-user-record','*', "record_id = '#{record_id}'")
    record = user.items.first
    
    if record
      render :text => record.key  #this contains app_id.publisher_user_id
    else
      render :text => "not_found"
    end
  end
  
end
