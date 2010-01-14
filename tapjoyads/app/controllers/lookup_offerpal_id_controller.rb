class LookupOfferpalIdController < ApplicationController
         
  def index
    int_id = params[:int_id].gsub("'", '')
    user = PublisherUserRecord.select(:where => "int_record_id = '#{int_id}'")
    record = user.items.first
    
    if record
      render :text => record.key  #this contains app_id.publisher_user_id
    else
      render :text => "not_found"
    end
    
  end         

  def reverse
    record_id = params[:record_id].gsub("'", '')
    user = PublisherUserRecord.select(:where => "record_id = '#{record_id}'")
    record = user.items.first
    
    if record
      render :text => record.key  #this contains app_id.publisher_user_id
    else
      render :text => "not_found"
    end
  end
  
  def store
    record_id = params[:record_id].gsub("'", '')
    store_click = StoreClick.select(:where => "publisher_user_record_id = '#{record_id}'")
    record = store_click.items.first
    
    if record
      render :text => record.key  #this contains app_id.publisher_user_id
    else
      render :text => "not_found"
    end
  end
  
end
