class TjmRequest < SyslogMessage

  self.define_attr :session_id
  self.define_attr :session_started_at, :type => :time
  self.define_attr :gamer_id
  self.define_attr :device_id
  self.define_attr :controller
  self.define_attr :action
  self.define_attr :referrer
  self.define_attr :http_referrer, :cgi_escape => true

  def add_standard_attributes(session, request, gamer, device_id, ip_address, geoip_data, params)
    self.session_id         = session[:tjm_session_id]
    self.session_started_at = session[:tjm_session_started_at]
    self.controller         = params[:controller]
    self.action             = params[:action]
    self.gamer_id           = gamer.id if gamer.present?
    self.device_id          = device_id if device_id.present?
    self.user_agent         = request.user_agent
    self.ip_address         = ip_address
    self.geoip_country      = geoip_data[:country]
    self.referrer           = params[:referrer]
    self.http_referrer      = request.referrer
  end

end
