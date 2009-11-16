xml.instruct!

xml.TapjoyConnectReturnObject do
  xml.TapjoyAdObject do
    xml.ClickURL(@ad_return_obj.ClickURL)
    xml.Image(@ad_return_obj.Image)
    unless @ad_return_obj.AdMessage.nil? 
      xml.AdMessage(@ad_return_obj.AdMessage)
    end
    xml.AdImpressionID(@ad_return_obj.AdImpressionID)
    xml.AdID(@ad_return_obj.AdID)
    unless @ad_return_obj.AdHTML.nil?
      xml.AdHTML(@ad_return_obj.AdHTML)
    end
    xml.OpenIn(@ad_return_obj.OpenIn)
    xml.GameID(@ad_return_obj.GameID)
  end
end