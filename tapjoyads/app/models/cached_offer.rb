class CachedOffer < SimpledbResource
  self.domain_name = 'cached-offer'
  
  def get_description(currency, publisher_app)
    return get('description').
        gsub("TAPJOY_BUCKS", currency.get('currency_name')).
        gsub('TAPJOY_APP_NAME', publisher_app.get('name'))
  end
  
  def get_name(currency, publisher_app)
    return get('name').
        gsub("TAPJOY_BUCKS", currency.get('currency_name')).
        gsub('TAPJOY_APP_NAME', publisher_app.get('name'))
  end
  
  def get_instructions(currency, publisher_app)
    return get('instructions').
        gsub("TAPJOY_BUCKS", currency.get('currency_name')).
        gsub('TAPJOY_APP_NAME', publisher_app.get('name'))
  end
  
  def get_action_url(publisher_user_record, publisher_app = nil, udid = nil, app_version = nil)
    if get('type') == 'rate_app'
      return "http://ws.tapjoyads.com/rate_app_offer" +
          "?record_id=#{publisher_user_record.get_record_id}" +
          "&udid=#{udid}" +
          "&app_id=#{publisher_app.key}" +
          "&app_version=#{app_version}"
    end
    return get('action_url').gsub(" ","%20").gsub('TAPJOY_GENERIC', publisher_user_record.get_int_record_id)
  end
  
  def get_email_url(publisher_user_record, publisher_app, udid)
    if get('type') == 'rate_app'
      return ''
    end
    return "http://www.tapjoyconnect.com/complete_offer" +
        "?offerid=#{CGI::escape(@key)}" +
        "&udid=#{udid}" +
        "&record_id=#{publisher_user_record.get_record_id}" +
        "&app_id=#{publisher_app.key}" +
        "&url=#{CGI::escape(CGI::escape(get_action_url(publisher_user_record)))}"
  end
end