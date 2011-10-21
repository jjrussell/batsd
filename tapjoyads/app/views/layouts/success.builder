xml.instruct!
xml.TapjoyConnectReturnObject do
  xml.Success true
  xml.Message @message if defined? @message
end
