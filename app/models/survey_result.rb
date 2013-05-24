class SurveyResult < SimpledbResource
  include RiakMirror
  mirror_configuration :riak_bucket_name => "survey_results", :read_from_riak => true

  self.domain_name = 'survey_results'

  self.sdb_attr :udid
  self.sdb_attr :click_key
  self.sdb_attr :answers, :type => :json, :cgi_escape => true
  self.sdb_attr :geoip_data, :type => :json, :cgi_escape => true

end
