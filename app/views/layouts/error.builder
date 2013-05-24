xml.instruct!
xml.TapjoyConnectReturnObject do
  xml.Success false
  xml.Message @error_message if defined? @error_message
end
