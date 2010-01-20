class App < SimpledbResource
  self.domain_name = 'app'
  self.key_format = 'app_guid'
  
  def get_linkshare_url(request = nil, params = nil)
    store_url = get('store_url')
    
    match = store_url.match(/\/id(\d*)\?/)
    unless match
      match = store_url.match(/[&|?]id=(\d*)/)
    end
    
    unless match and match[1]
      if request and params
        NewRelic::Agent.agent.error_collector.notice_error(
            Exception.new("Could not parse store id from #{store_url}"),
            request, action, params)
      end
      return store_url
    end
    
    store_id = match[1]
    web_object_url = "http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=#{store_id}&mt=8"
    
    return "http://click.linksynergy.com/fs-bin/click?id=OxXMC6MRBt4&subid=&offerid=146261.1&" +
        "type=10&tmpid=3909&RD_PARM1=#{CGI::escape(web_object_url)}"
  end
end