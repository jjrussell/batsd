class GetAdOrderController < ApplicationController
  include MemcachedHelper
    
  def index
    return unless verify_params([:app_id, :udid])

    app_id = params[:app_id]
    mc_key = "ad_order.#{params[:app_id]}"
    
    ad_order_data = get_from_cache(mc_key) do 
      ## get order
      campaigns = SimpledbResource.select('campaign', '*', "status='1' and app_id='#{app_id}' and ecpm != ''", "ecpm desc")
      
      json = campaigns.items.to_json
      
      save_to_cache(mc_key, json, false, 5.minutes)
      
      #return json
      json
    end
    
    json = JSON.parse(ad_order_data)
    
    app = App.new(params[:app_id])
  
    @ad_order = AdOrder.new
    
    @ad_order.RotationTime = app.get('rotation_time')
    @ad_order.RotationDirection = app.get('rotation_direction')
    @ad_order.HasLocation = "False" #app.get('has_location')
    
    @ad_order.networks = []
    count = 0
    
    json.each do |campaign_item|
      network = AdOrderCampaign.new
      campaign = campaign_item['attributes']
      network.AdCampaignId = campaign_item['key']
      
      network.AdNetworkGameID1 = campaign['id1'] if campaign['id1'] != 'None'
      network.AdNetworkGameID2 = campaign['id2'] if campaign['id2'] != 'None'
      network.AdNetworkGameID3 = campaign['id3'] if campaign['id3'] != 'None'
      network.EventInterval1 = campaign['event1']
      network.EventInterval2 = campaign['event2']
      network.EventInterval3 = campaign['event3']
      network.EventInterval4 = campaign['event4']
      network.EventInterval5 = campaign['event5']
      network.CallAdShown = campaign['call_ad_shown'] if campaign['call_ad_shown'] == 'False'
      network.AdLibraryName = campaign['library_name']
      network.AdFormat = campaign['format']
      network.CustomAd = campaign['custom_ad'] if campaign['custom_ad'] == 'True'
      network.Bar = campaign['bar'] if campaign['bar'] == 'True'
      @ad_order.networks[count] = network
      count += 1
    end
    
    @ad_order.LastNetwork = count - 1
    @ad_order.LastNetwork = 0 if count == 0

  end
end