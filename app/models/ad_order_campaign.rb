class AdOrderCampaign
  attr_accessor :AdCampaignId, :AdLibraryName, :MaxTimesToShowAdOnDevice,
  :EventInterval1, :EventInterval2, :EventInterval3, :EventInterval4, :EventInterval5,
  :AdNetworkGameID1, :AdNetworkGameID2, :AdNetworkGameID3, :CallAdShown, :AdFormat, :CustomAd,
  :AdLibraryName, :Bar

  def initialize()
    @AdNetworkGameID1 = ''
    @AdNetworkGameID2 = ''
    @AdNetworkGameID3 = ''
    @EventInterval1 = '1'
    @EventInterval2 = '1'
    @EventInterval3 = '1'
    @EventInterval4 = '1'
    @EventInterval5 = '1'
    @CallAdShown = "true"
    @AdFormat = "0"
    @CustomAd = "false"
    @AdLibraryName = nil
    @Bar = "false"
    @MaxTimesToShowAdOnDevice = "-1"
  end
end
