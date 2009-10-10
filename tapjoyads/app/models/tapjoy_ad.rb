class TapjoyAd
  attr_accessor :ClickURL, :Image, :AdMessage, :AdImpressionID, :AdID, :AdHTML, :OpenIn
  
  def initialize()
    @AdImpressionID = "00000000-0000-0000-0000-000000000000"
    @AdID = "00000000-0000-0000-0000-000000000000"
    @AdHTML = nil
    @OpenIn = "Safari"
    @AdMessage = nil
  end
  
end