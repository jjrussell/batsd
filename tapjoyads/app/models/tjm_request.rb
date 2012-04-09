class TjmRequest < SyslogMessage

  PATH_MAP = {
    'homepage' => {
      'index'             => 'home',
      'show'              => 'my_profile',
      'send_device_link'  => 'email_device_link',
      'switch_device'     => 'switch_device',
      'help'              => 'help',
      'earn'              => 'view_installed_app',
      'get_app'           => 'get_app',
      'privacy'           => 'privacy_policy',
      'tos'               => 'terms_of_use',
    },
    'app_reviews' => {
      'new'       => 'app_review',
      'update'    => 'update_app_review',
    },
    'more_games'  => {
      'editor_picks'    => 'view_more_apps',
      'recommended'     => 'recommended_apps',
    },
    'gamers' => {
      'new'             => 'signup_form',
      'show'            => 'view_profile',
      'create'          => 'signup_attempt',
      'confirm_delete'  => 'pre_delete_confirm',
      'destroy'         => 'account_delete',
      'password'        => 'change_password_attempt',
      'update_password' => 'password_changed',
    },
    'gamer_sessions' => {
      'create'    => 'login_attempt',
      'destroy'   => 'logout',
    },
    'gamers/favorite_app' => {
      'create'    => 'mark_app_favorite',
      'destroy'   => 'remove_app_favorite',
    },
    'gamers/gamer_profiles' => {
      'show'      => 'view_account',
      'edit'      => 'edit_account',
      'update'    => 'account_info_changed',
    },
    'password_resets' => {
      'new'       => 'forgot_password',
      'create'    => 'send_password_reset',
      'edit'      => 'change_password',
      'update'    => 'password_changed',
    },
    'social' => {
      'index'                       => 'social_home',
      'friends'                     => 'view_friends',
      'invites'                     => 'find_friends',
      'invite_email_friends'        => 'invite_by_email',
      'send_email_invites'          => 'invite_email_sent',
      'connect_facebook_account'    => 'facebook_connect',
      'invite_twitter_friends'      => 'view_twitter_invite',
      'get_twitter_friends'         => 'get_twitter_friends',
      'send_twitter_invites'        => 'invite_twitter_sent',

    },
    'support_requests' => {
      'new'       => 'view_contact_form',
      'create'    => 'contact_tapjoy',
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

  private

  def lookup_path
    subbed_controller = controller.sub(/^games\//,'')
    PATH_MAP.include?(subbed_controller) && PATH_MAP[subbed_controller].include?(action) ? PATH_MAP[subbed_controller][action] : "tjm_#{controller}_#{action}"
  end

end
