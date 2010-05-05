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
    raise "Not implemented"
  end
  
end
