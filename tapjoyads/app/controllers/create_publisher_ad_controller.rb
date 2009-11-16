class CreatePublisherAdController < ApplicationController
  
  def index
    xml = <<XML_END
<?xml version="1.0" encoding="UTF-8"?>
<TapjoyConnectReturnObject>
<Success>true</Success>
</TapjoyConnectReturnObject>
XML_END

    if ( (not params[:ad_id]) || (not params[:partner_id]) )
      error = Error.new
      error.put('request', request.url)
      error.put('function', 'connect')
      error.put('ip', request.remote_ip)
      error.save
      Rails.logger.info "missing required params"
      render :text => "missing required params"
      return
    end
    
    now = Time.now
    
    ad_id = params[:ad_id]
  
    ad = PublisherAd.new(ad_id)
    ad.put('partner_id', params[:partner_id])
    ad.put('app_id_to_advertise', params[:app_id_to_advertise]) if params[:app_id_to_advertise]
    ad.put('app_id_restricted', params[:app_id_restricted]) if params[:app_id_restricted]
    ad.put('name', params[:name])
    ad.put('description', params[:description])
    ad.put('url', params[:url])
    ad.put('open_in', params[:open_in])
    ad.put('max_daily_impressions', params[:max_daily_impressions]) if params[:max_daily_impressions]
    ad.put('max_total_impressions', params[:max_total_impressions]) if params[:max_total_impressions]
    ad.put('cpc', params[:cpc]) if params[:cpc]
    ad.put('cpa', params[:cpa]) if params[:cpa]    
    ad.put('cpm', params[:cpm]) if params[:cpm]
    
    
  
    logger.info "Created Ad object (#{Time.now - now}s)"
    now = Time.now
  
    Thread.new do
      start_time = Time.now
      ad.save
      logger.info "Ad sdb save (#{Time.now - start_time}s)"
      logger.flush
    
      #store an image in s3
      start_time = Time.now
      AWS::S3::S3Object.store ad_id, params[:image], 'publisher_ads'
    
      logger.info "Stored in s3 (#{Time.now - start_time}s)"
      logger.flush
    end
  
    logger.info "Spawned thread (#{Time.now - now}s)"
  
    respond_to do |f|
      f.xml {render(:text => xml)}
    end
    
  end
  
end
