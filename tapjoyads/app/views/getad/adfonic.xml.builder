xml.instruct!

xml.TapjoyConnectReturnObject do
  xml.TapjoyAdObject do
    xml.ClickURL(@tjad.ClickURL)
    xml.Image(@tjad.Image)
    unless @tjad.AdMessage.nil? 
      xml.AdMessage(@tjad.AdMessage)
    end
    xml.AdImpressionID(@tjad.AdImpressionID)
    xml.AdID(@tjad.AdID)
    unless @tjad.AdHTML.nil?
      xml.AdHTML(@tjad.AdHTML)
    end
    xml.OpenIn(@tjad.OpenIn)
  end
end
