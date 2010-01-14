# Gets the list of offers from offerpal

class Job::CreateRewardedInstallsController < Job::SqsReaderController
  include DownloadContent
  include MemcachedHelper
  
  def initialize
    super QueueNames::CREATE_REWARDED_INSTALLS
  end
  
  private 
  
  def on_message(message)
    
    #first get the list of all apps paying for installs
    app_list = []
    App.select(
        :where => "payment_for_install > '0' and install_tracking = '1' and rewarded_installs_ordinal != '' and balance > '0'",
        :order_by => "rewarded_installs_ordinal") do |item|
      app_list.push(item)
    end
    
    #now get the list of all apps with currency
    app_currency_list = []
    Currency.select(:where => "currency_name != ''") do |item|
      app_currency_list.push(item)
    end
      
    #go through and create app-specific lists for each app
    app_currency_list.each do |currency|
      
      Rails.logger.info "Creating rewarded install xml for #{currency.key} of #{currency.get('currency_name')}"
      banned_apps = currency.get('disabled_apps').split(';') if currency.get('disabled_apps')
      
      xml = ""
      app_list.each do |app|
        next if (banned_apps) && (banned_apps.include? app.key)
        next if app.key == currency.key
        return_offer = ReturnOffer.new(1, app, currency)
        xml += return_offer.to_xml
        xml += "TAPJOY_IPHONE_ONLY" if app.get('iphone_only') == '1'
        xml += "^^TAPJOY_SPLITTER^^"
      end
        
      AWS::S3::S3Object.store "installs_" + currency.key, 
        xml, RUN_MODE_PREFIX + 'offer-data'
      save_to_cache("installs.s3.#{currency.key}", xml)
      
      xml = ""
      app_list.each do |app|
        next if (banned_apps) && (banned_apps.include? app.key)
        next if app.key == currency.key
        return_offer = ReturnOffer.new(1, app, currency)
        return_offer.AppID = currency.key
        xml += return_offer.to_server_xml
        xml += "TAPJOY_IPHONE_ONLY" if app.get('iphone_only') == '1'
        xml += "^^TAPJOY_SPLITTER^^"
      end
        
      AWS::S3::S3Object.store "server.installs_" + currency.key, 
        xml, RUN_MODE_PREFIX + 'offer-data'
      save_to_cache("server.installs.s3.#{currency.key}", xml)
      
      xml = ""
      app_list.each do |app|
        next if (banned_apps) && (banned_apps.include? app.key)
        next if app.key == currency.key
        return_offer = ReturnOffer.new(1, app, currency)
        return_offer.AppID = currency.key
        xml += return_offer.to_server_xml_redirect
        xml += "TAPJOY_IPHONE_ONLY" if app.get('iphone_only') == '1'
        xml += "^^TAPJOY_SPLITTER^^"
      end
        
      AWS::S3::S3Object.store "redirect.installs_" + currency.key, 
        xml, RUN_MODE_PREFIX + 'offer-data'
      save_to_cache("redirect.installs.s3.#{currency.key}", xml)
    end
  end
end