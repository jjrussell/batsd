class LookupOfferpalIdController < ApplicationController
  include PublisherRecordHelper
  
  def index
    begin
      record_key = lookup_by_int_record(params[:int_id])
      render :text => record_key
    rescue RecordNotFoundException => e
      render :text => "not_found"
    end
  end         

  def reverse
    begin
      record_key =  lookup_by_record(params[:record_id])
      render :text => record_key
    rescue RecordNotFoundException => e
      render :text => "not_found"
    end
  end
  
  def store
    record_id = params[:record_id].gsub("'", '')
    store_click = StoreClick.select(:where => "publisher_user_record_id = '#{record_id}'").items.first
    
    if record
      render :text => store_click.key
    else
      render :text => "not_found"
    end
  end
  
end
