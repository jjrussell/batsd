class TapPointsController < ApplicationController
  include DownloadContent
  
  def add
    
    parts = params[:snuid].split('.')
    
    if parts.length < 2
      url = "http://www.tapjoyconnect.com.asp1-3.dfw1-1.websitetestlink.com/Service1.asmx/LookupPointId?pointid=#{params[:snuid]}"
      response = download_content(url, :return_response => true)
      raise "snuid: #{params[:snuid]} not found in mosso lookup: #{response.body}" if response.status != 200 
      parts = response.body.split('.')
    end
      
    udid = parts[0]
    app_id = parts[1]
      

    amount = params[:currency]
    
    lock_on_key("lock.purchase_vg.#{udid}.#{app_id}") do
      point_purchases = PointPurchases.new(:key => "#{params[:udid]}.#{params[:app_id]}")
      
      Rails.logger.info "Adding #{amount} from #{params[:snuid]}, to user balance: #{point_purchases.points}"
  
      
      point_purchases.points = point_purchases.points + amount.to_i
  
      point_purchases.serial_save(:catch_exceptions => false)
    end
  
  end
  
end