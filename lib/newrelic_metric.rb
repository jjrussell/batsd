class NewrelicMetric
  NEWRELIC_APP_ID = 18553
  API_KEY = begin
    YAML::load_file("config/newrelic.yml")[Rails.env]['license_key']
  rescue => e
    puts "we probably don't care about this ; #{e}"
  end

  def self.get(metric, field)
    now = Time.now.utc
    start_time = (now - 60).strftime('%Y-%m-%dT%H:%M:00Z')
    end_time = now.strftime('%Y-%m-%dT%H:%M:00Z')

    url = "https://api.newrelic.com/api/v1/applications/#{NEWRELIC_APP_ID}/data.xml?field=#{field}&metrics[]=#{metric}&begin=#{start_time}&end=#{end_time}&summary=1"
    response = HTTParty.get(url, :headers => {'x-api-key' => API_KEY})

    stat = Crack::XML.parse(response.body)
    stat['metrics'].first['field'].to_f
  end
end
