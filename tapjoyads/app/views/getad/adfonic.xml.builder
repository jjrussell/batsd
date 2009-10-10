xml.instruct!

xml.TapjoyConnectReturnObject do
  xml.TapjoyAdObject do
    xml.ClickURL(@tjad.ClickURL)
    xml.Image(@tjad.Image)
    xml.AdMessage(@tjad.AdMessage)
    xml.AdImpressionID(@tjad.AdImpressionID)
    xml.AdID(@tjad.AdID)
    xml.AdHTML(@tjad.AdHTML)
    xml.OpenIn(@tjad.OpenIn)
  end
end
