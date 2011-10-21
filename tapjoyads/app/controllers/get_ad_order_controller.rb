class GetAdOrderController < ApplicationController
    
  def index
    return unless verify_params([ :app_id, :udid ])

    app = App.find_in_cache(params[:app_id])
    return unless verify_records([ app ])

    mc_key = "raw_ad_order.#{params[:app_id]}"
    
    campaigns = Mc.get_and_put(mc_key, false, 5.minutes) do 
      c = Campaign.select(:where => "status='1' and app_id='#{params[:app_id]}' and ecpm != ''", :order_by => "ecpm desc")
      c[:items]
    end
  
    @ad_order = AdOrder.new
    
    @ad_order.RotationTime = app.rotation_time
    @ad_order.RotationDirection = app.rotation_direction
    @ad_order.HasLocation = "False"
    
    @ad_order.networks = []
    count = 0
    
    campaigns.each do |campaign|
      network = AdOrderCampaign.new
      network.AdCampaignId = campaign.key
      
      network.AdNetworkGameID1 = campaign.get('id1') if campaign.get('id1') != 'None'
      network.AdNetworkGameID2 = campaign.get('id2') if campaign.get('id2') != 'None'
      network.AdNetworkGameID3 = campaign.get('id3') if campaign.get('id3') != 'None'
      network.EventInterval1 = campaign.get('event1')
      network.EventInterval2 = campaign.get('event2')
      network.EventInterval3 = campaign.get('event3')
      network.EventInterval4 = campaign.get('event4')
      network.EventInterval5 = campaign.get('event5')
      network.CallAdShown = campaign.get('call_ad_shown') if campaign.get('call_ad_shown') == 'False'
      network.AdLibraryName = campaign.get('library_name')
      network.AdFormat = campaign.get('format')
      network.CustomAd = "true" if (network.AdLibraryName == "customsdk")
      network.AdLibraryName = campaign.get('name') if (network.AdLibraryName == "customsdk")
      network.Bar = campaign.get('bar') if campaign.get('bar') == 'True'
      @ad_order.networks[count] = network
      count += 1
    end
    
    @ad_order.LastNetwork = count - 1
    @ad_order.LastNetwork = 0 if count == 0

  end
end
