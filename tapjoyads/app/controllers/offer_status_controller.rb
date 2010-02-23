class OfferStatusController < ApplicationController
  include DownloadContent
  
  def index
    return unless verify_params([:app_id, :udid], {:allow_empty => false})
    
    @publisher_user_record = PublisherUserRecord.new(
        :key => "#{params[:app_id]}.#{params[:publisher_user_id]}")
        
    currency = Currency.new(:key => "#{params[:app_id]}")
    
    @snuid = @publisher_user_record.get('int_record_id')
    offerpal_status_url = "http://pub.myofferpal.com/b7b401f73d98ff21792b49117edd8b9f/userstatusAPI.action?snuid=#{@snuid}&callbackFormat=json"
    
    response = download_content(offerpal_status_url, :timeout => 4)   
    
    response = response.gsub('##CURRENCY', currency.get('currency_name'))
    
    json = JSON.parse(response)
    
    @status_items = json['offerStatus']
    @email = json['customerServiceEmail']
    
    web_request = WebRequest.new
    web_request.put_values('offer_status', params, request)
    web_request.save

  end
end