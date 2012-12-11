class SurveyResult < SimpledbResource
  include RiakMirror
  mirror_configuration :riak_bucket_name => "survey_results"

  self.domain_name = 'survey_results'

  self.sdb_attr :udid
  self.sdb_attr :tapjoy_device_id
  self.sdb_attr :click_key
  self.sdb_attr :answers, :type => :json, :cgi_escape => true
  self.sdb_attr :geoip_data, :type => :json, :cgi_escape => true

  def tapjoy_device_id
    get('tapjoy_device_id') || udid
  end

  def tapjoy_device_id=(tj_id)
    put('tapjoy_device_id', tj_id)
  end
end
