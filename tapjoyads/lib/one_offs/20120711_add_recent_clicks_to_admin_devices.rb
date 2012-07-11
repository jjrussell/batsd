now = Time.now
devices = AdminDevice.ordered_by_description
devices.each do |device|
  udid = device.udid
  conditions = ["udid = '#{udid}'",
                "clicked_at > '#{(now - Device::RECENT_CLICKS_RANGE).to_i}'",
                ].join(' and ')
  device_clicks = []
  NUM_CLICK_DOMAINS.times do |i|
    Click.select(:domain_name => "clicks_#{i}", :where => conditions) do |click|
      device_clicks << click
    end
  end
  next if device_clicks.empty?

  device_clicks.sort! {|x,y| x.clicked_at <=> y.clicked_at}
  device_clicks.each do |click|
    device.add_click(click)
  end
end
