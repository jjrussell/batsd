class Games::TapjoygamesMobileconfigController < GamesController
  def index
    render :xml => <<-EOF
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
       <key>PayloadContent</key>
       <dict>
        <key>URL</key>
        <string>https://www.tapjoygames.com/gamers/update</string>
        <key>DeviceAttributes</key>
        <array>
         <string>UDID</string>
         <string>IMEI</string>
         <string>ICCID</string>
         <string>VERSION</string>
         <string>PRODUCT</string>
        </array>
       </dict>
       <key>PayloadOrganization</key>
       <string>tapjoygames.com</string>
       <key>PayloadDisplayName</key>
       <string>Tapjoy Games</string>
       <key>PayloadVersion</key>
       <integer>1</integer>
       <key>PayloadUUID</key>
       <string>A4873F1B-F6F8-424F-A2BC-85A1B9FC55C1</string>
       <key>PayloadIdentifier</key>
       <string>com.tapjoygames.profile-service</string>
       <key>PayloadDescription</key>
       <string>Tapjoy Games is the #1 destination for discovering mobile games and apps.</string>
       <key>PayloadType</key>
       <string>Profile Service</string>
      </dict>
      </plist>
    EOF
  end
end