class TjmRequest < SyslogMessage

  PATH_MAP = {
    'password_resets' => {
      'new'    => 'tjm_forgot_password',
      'create' => 'tjm_send_password_reset',
      'edit'   => 'tjm_change_password',
      'update' => 'tjm_password_changed',
    },
  }

  self.define_attr :session_id
  self.define_attr :session_start_time, :type => :time
  self.define_attr :session_last_active_time, :type => :time
  self.define_attr :http_referrer, :cgi_escape => true
  self.define_attr :controller
  self.define_attr :action
  self.define_attr :referrer
  self.define_attr :gamer_id
  self.define_attr :device_id

  def initialize(options = {})
    session    = options.delete(:session)    { |k| raise "#{k} is a required argument" }
    request    = options.delete(:request)    { |k| raise "#{k} is a required argument" }
    ip_address = options.delete(:ip_address) { |k| raise "#{k} is a required argument" }
    geoip_data = options.delete(:geoip_data) { |k| raise "#{k} is a required argument" }
    params     = options.delete(:params)     { |k| raise "#{k} is a required argument" }
    gamer      = options.delete(:gamer)
    device_id  = options.delete(:device_id)
    super(options)

    self.session_id               = session[:tjms_id]
    self.session_start_time       = session[:tjms_stime]
    self.session_last_active_time = session[:tjms_ltime]
    self.user_agent               = request.user_agent
    self.http_referrer            = request.referrer
    self.ip_address               = ip_address
    self.geoip_country            = geoip_data[:country]
    self.controller               = params[:controller]
    self.action                   = params[:action]
    self.referrer                 = params[:referrer]
    self.path                     = lookup_path
    self.gamer_id                 = gamer.id if gamer.present?
    self.device_id                = device_id if device_id.present?
  end

  def update_path(request_controller, request_action)
    self.controller = request_controller
    self.action = request_action
    self.path = lookup_path
  end

  private

  def lookup_path
    PATH_MAP.include?(controller) && PATH_MAP[controller].include?(action) ? PATH_MAP[controller][action] : "tjm_#{controller}_#{action}"
  end

end
