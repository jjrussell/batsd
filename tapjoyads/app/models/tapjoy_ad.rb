class TapjoyAd
  attr_accessor :ClickURL, :Image, :AdMessage, :AdImpressionID, :AdID, :AdHTML, :OpenIn, :GameID
  
  def initialize()
    @GameID = "00000000-0000-0000-0000-000000000000"
    @AdImpressionID = "00000000-0000-0000-0000-000000000000"
    @AdID = "00000000-0000-0000-0000-000000000000"
    @AdHTML = nil
    @OpenIn = "Safari"
    @AdMessage = nil
  end
  
end