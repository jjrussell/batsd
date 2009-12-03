# Gets the list of offers from offerpal

class Job::CreateRewardedInstallsController < Job::JobController
  include DownloadContent
  
  def index
    
    #first get the list of all apps paying for installs
    next_token = nil
    app_list = []
    while next_token != nil && next_token != ''
      app_items = SimpledbResource.select('app','app_id, payment_for_install, name, price, description1, description2, description3, description4', 
        "payment_for_install > '0' and install_tracking = '1' ", " rewarded_installs_ordinal, price, payment_for_install descending")
      next_token = app_items.next_token
      app_list.push(app_items)
    end
    
    #now get the list of all apps with currency
    next_token = nil
    app_currency_list = []
    while next_token != nil && next_token != ''
      app_items_list = SimpledbResource.select('app','app_id, currency_name, conversion_rate, money_share, banned_offers', 
        "currency_name != ''")
      next_token = app_items_list.next_token
      app_currency_list.push(app_items_list)
    end
      
    #go through and create app-specific lists for each app
    app_currency_list.each do |currency|
      banned_apps = currency.get('banned_apps').split(';') if currency.get('banned_apps')
      
      xml = "<OfferArray>\n"
      app_list.each do |app|
        next if banned.offers.contains offer.key
        return_offer = ReturnOffer.new(1, app, currency.get('installs_money_share'), currency.get('conversion_rate'))
        xml += return_offer.to_xml
      end
      xml += "</OfferArray>\n^^TAPJOY_SPLITTER^^"
      
      AWS::S3::S3Object.store "installs_" + currency.get('app_id'), 
        xml, 'offer_lists'
      
    end    
    
    render :text => "ok"
  end
end