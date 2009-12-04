# Gets the list of offers from offerpal

class Job::CreateRewardedInstallsController < Job::JobController
  include DownloadContent
  include MemcachedHelper
  
  def index
    
    #first get the list of all apps paying for installs
    next_token = nil
    app_list = []
    begin
      app_items = SimpledbResource.select('app','*', 
        "payment_for_install > '0' and install_tracking = '1' and rewarded_installs_ordinal != '' and balance > '0' ", " rewarded_installs_ordinal",
        next_token)
      next_token = app_items.next_token
      app_items.items.each do |item|
        app_list.push(item)
      end
    end while next_token != nil
    
    #now get the list of all apps with currency
    next_token = nil
    app_currency_list = []
    begin
      app_items_list = SimpledbResource.select('currency','currency_name, conversion_rate, installs_money_share, disabled_offers', 
        "currency_name != ''", nil, next_token)
      next_token = app_items_list.next_token
      app_items_list.items.each do |item|
        app_currency_list.push(item)
      end
    end while next_token != nil
      
    #go through and create app-specific lists for each app
    app_currency_list.each do |currency|
      banned_apps = currency.get('disabled_apps').split(';') if currency.get('disabled_apps')
      
      xml = "<OfferArray>\n"
      app_list.each do |app|
        next if (banned_apps) && (banned_apps.include? app.key)
        return_offer = ReturnOffer.new(1, app, currency.get('installs_money_share'), currency.get('conversion_rate'), 
          currency.get('currency_name'))
        xml += return_offer.to_xml
        xml += "^^TAPJOY_SPLITTER^^"
      end
      xml += "</OfferArray>\n"
      
      AWS::S3::S3Object.store "installs_" + currency.key, 
        xml, 'offer-data'
      save_to_cache("installs.s3.#{currency.key}", xml)
    end    
    
    render :text => "ok"
  end
end