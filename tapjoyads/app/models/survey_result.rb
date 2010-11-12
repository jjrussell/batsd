class SurveyResult < SimpledbResource
  
  self.domain_name = 'survey_results'
  
  self.sdb_attr :udid
  self.sdb_attr :click_key
  self.sdb_attr :answers, :type => :json
  self.sdb_attr :geoip_data, :type => :json
  
end