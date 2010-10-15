# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  
  before_filter :fix_params
  before_filter :reject_banned_ips
  before_filter :choose_experiment

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'f9a08830b0e4e7191cd93d2e02b08187'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  filter_parameter_logging :password, :password_confirmation
  
private
  
  def verify_params(required_params, options = {})
    allow_empty = options.delete(:allow_empty) { true }
    render_missing_text = options.delete(:render_missing_text) { true }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
    all_params = true
    required_params.each do |param|
      all_params = false unless params.include?(param)
      unless allow_empty
        all_params = false if params[param] == ''
      end
    end
    
    unless all_params
      log_missing_required_params
      render :text => "missing required params" if render_missing_text
    end
    return all_params
  end
  
  def log_missing_required_params
    Rails.logger.info "missing required params"
    if params[:udid] != 'null'
      NewRelic::Agent.add_custom_parameters({ :user_agent => request.headers['User-Agent'] })
      Notifier.alert_new_relic(MissingRequiredParamsError, request.url, request, params)
    end
  end
  
  def fix_params
    downcase_param(:udid)
    downcase_param(:app_id)
    downcase_param(:campaign_id)
    downcase_param(:publisher_app_id)
    downcase_param(:publisher_user_record_id)
    downcase_param(:offer_id)
    downcase_param(:type)
    set_param(:udid, :DeviceTag, true)
    set_param(:app_id, :AppID, true)
    set_param(:device_os_version, :DeviceOSVersion)
    set_param(:device_type, :DeviceType)
    set_param(:library_version, :ConnectLibraryVersion)
    set_param(:app_version, :AppVersion)
    set_param(:campaign_id, :CampaignID, true)
    set_param(:campaign_id, :AdCampaignID, true)
    set_param(:advertiser_app_id, :AdvertiserAppID, true)
    set_param(:publisher_app_id, :AppID, true)
    set_param(:publisher_user_id, :PublisherUserRecordID)
    set_param(:campaign_id, :AdImpressionID, true)
    set_param(:offer_id, :CachedOfferID, true)
    set_param(:type, :Type, true)
    set_param(:publisher_user_id, :PublisherUserID)
    set_param(:start, :Start)
    set_param(:max, :Max)
    set_param(:virtual_good_id, :VirtualGoodID)
    set_param(:library_version, :ConnectLibraryVersion)
  end
  
  def downcase_param(p)
    params[p] = params[p].downcase if params[p]
  end
  
  def set_param(to, from, lower = false)
    if (not params[to]) && params[from]
      params[to] = params[from] 
      params[to] = params[to].downcase.strip if lower
    end
  end
  
  def get_ip_address
    return @request_ip_address if defined?(@request_ip_address)
    @request_ip_address = (request.headers['X-Forwarded-For'] || request.remote_ip).gsub(/,.*$/, '')
  end
  
  def get_geoip_data
    data = {}
    ip_address = params[:device_ip] || get_ip_address
    
    begin
      array = GEOIP.city(ip_address)
    rescue Exception => e
      Rails.logger.info "Error getting GeoIP data: #{e}"
      array = nil
    end
    
    unless array.nil?
      data[:country] = array[2]
      data[:continent] = array[5]
      data[:region] = array[6]
      data[:city] = array[7]
      data[:postal_code] = array[8]
      data[:lat] = array[9]
      data[:long] = array[10]
      data[:area_code] = array[12]
    end
    
    data
  end
  
  def reject_banned_ips
    banned_ips = Set.new(['174.120.96.162', '151.197.180.227', '74.63.224.218', '65.19.143.2'])
    render :text => '' if banned_ips.include?(get_ip_address)
  end
  
  def log_activity(object)
    @request_id = UUIDTools::UUID.random_create.to_s unless defined?(@request_id)
    @activity_logs = [] unless defined?(@activity_logs)
    
    activity_log = ActivityLog.new({ :load => false })
    activity_log.request_id = @request_id
    activity_log.user = 'system'
    activity_log.user = current_user.username if self.respond_to?(:current_user)
    activity_log.controller = params[:controller]
    activity_log.action = params[:action]
    activity_log.object = object
    @activity_logs << activity_log
  end
  
  def save_activity_logs
    if defined?(@activity_logs)
      @activity_logs.each do |activity_log|
        activity_log.finalize_states
        activity_log.save
      end
    end
  end
  
  def determine_link_affiliates
    if App::TRADEDOUBLER_COUNTRIES.include?(get_geoip_data[:country])
      @itunes_link_affiliate = 'tradedoubler'
    else
      @itunes_link_affiliate = 'linksynergy'
    end
  end
    
  def choose_experiment
    params[:exp] = Experiments.choose(params[:udid]) unless params[:exp].present?
  end
  
end
