class Job::RateOfferQueueController < Job::SqsReaderController
  include DownloadContent
  
  def initialize
    super QueueNames::RATE_OFFER
  end
  
  private
  
  def on_message(message)
    json = JSON.parse(message.to_s)
    udid = json['udid']
    app_id = json['app_id']
    record_id = json['record_id']
    
    Rails.logger.info "Checking rating info on #{udid} for #{app_id} with #{record_id}"
    
    rate = RateApp.new(:key => "#{app_id}.#{udid}")
    unless rate.get('rate-date')
      Rails.logger.info "Sending rating info for #{record_id}"
      rate.put('rate-date', Time.now.utc.to_f.to_s)
      rate.save

      currency = Currency.new(:key => app_id)
      amount = (10.0 * currency.get('conversion_rate').to_f / 100.0.to_f).to_i.to_s

      win_lb = 'http://winweb-lb-1369109554.us-east-1.elb.amazonaws.com/Service1.asmx/'
      url = win_lb + "SubmitCompletedRatingOffer?password=nhytgbvfr" + 
        "&PublisherUserID=#{record_id}&AppID=#{app_id}&Currency=#{amount}"
      
      download_with_retry(url, {:timeout => 15}, {:retries => 3})
    end
  end
end