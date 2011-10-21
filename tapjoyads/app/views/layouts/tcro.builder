xml.instruct!
xml.TapjoyConnectReturnObject do
  if defined? @success
    xml.Success @success
  else
    xml.Success true
  end
  xml.Message @message if defined? @message
end
