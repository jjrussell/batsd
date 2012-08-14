class Dashboard::DashboardController < ApplicationController
  include SslRequirement

  layout 'website'

  skip_before_filter :fix_params
  skip_before_filter :force_utc

  helper_method :current_user, :current_partner, :current_partner_apps, :current_partner_offers, :current_partner_app_offers, :current_partner_active_app_offers, :current_partner_active_offers, :premier_enabled?

  before_filter { |c| Authorization.current_user = c.send(:current_user) }
  before_filter :check_employee_device
  before_filter :set_recent_partners
  before_filter :inform_of_new_sdk
  around_filter :set_time_zone

  NEW_SDK_NOTICE = "A new iOS SDK (v8.1.8) update is now available <a href='/sdk'>here</a> for both Publishers and Advertisers.
                    Moving forward, please update the Tapjoy SDK for all apps you're submitting to Apple. Our updated SDK now tracks w/ MAC Address.
                    If you have any questions/concerns, please contact <a href='mailto:support@tapjoy.com'>support@tapjoy.com</a>.
                    <br><br>Read more at our blog: <a href='http://blog.tapjoy.com/for-developers/tapjoy-sdk-update/'>http://blog.tapjoy.com/for-developers/tapjoy-sdk-update/</a>"

  def sanitize_currency_params(object, fields)
    unless object.nil?
      fields.each do |field|
        if object[field]
          object[field] = sanitize_currency_param(object[field])
        end
      end
    end
    object
  end

  def sanitize_currency_param(field)
    field.blank? ? field : (field.gsub(/[\$,]/,'').to_f * 100).round.to_s
  end

  def check_employee_device
    return unless Rails.env.production?
    if current_user && current_user.employee?
      if request.path.match(/logout|approve_device/)
        return
      elsif device = current_user.internal_devices.find_by_id(device_cookie)
        return if device.approved?
      end
      redirect_to new_internal_device_path
    end
  end

  def device_cookie
    @device_id ||= cookies["#{current_user.email}-device"]
  end

  def set_cookie(options)
    cookies["#{current_user.email}-device"] = options
  end

  protected

  def permission_denied
    flash[:error] = "Sorry, you are not allowed to access that page."
    if current_user
      destination = request.env['HTTP_REFERER'] =~ /tapjoy.com/ ? request.env['HTTP_REFERER'] : root_path
    else
      destination = login_path(:goto => request.path)
    end
    redirect_to(destination)
  end

  def ssl_required?
    Rails.env.production?
  end

  def current_user
    @current_user ||= current_user_session && current_user_session.record
  end

  private

  def current_partner
    @current_partner ||= current_user && (current_user.current_partner || current_user.partners.first)
  end

  def current_partner_apps
    @current_partner_apps ||= current_partner.apps.visible.sort_by{|app| app.name.downcase}
  end

  def current_partner_offers
    @current_partner_offers ||= current_partner.offers.visible.sort_by{|offer| offer.name_with_suffix.downcase}
  end

  def current_partner_app_offers
    @current_partner_app_offers ||= current_partner.offers.visible.app_offers.sort_by{|app| app.name.downcase}
  end

  def current_partner_active_app_offers
    @current_partner_active_app_offers ||= current_partner_app_offers.select(&:is_enabled?)
  end

  def current_partner_active_offers
    @current_partner_active_offers ||= current_partner_offers.select(&:is_enabled?).select(&:show_in_active_campaigns?)
  end

  def premier_enabled?
    current_partner.exclusivity_level.present?
  end

  def current_user_session
    @current_user_session ||= UserSession.find
  end

  def get_stat_prefix(group)
    @platform == 'all' ? group : "#{group}-#{@platform}"
  end

  def set_platform
    @platform = params[:platform] || 'all'
  end

  def set_time_zone
    old_time_zone = Time.zone
    Time.zone = current_user.time_zone if current_user.present?
    yield
  ensure
    Time.zone = old_time_zone
  end

  def inform_of_new_sdk
    if current_user && flash.now[:notice].blank? && (!cookies[:informed_sdk].present? || ObjectEncryptor.decrypt(cookies[:informed_sdk]) != '8.1.8')
      flash.now[:notice] = NEW_SDK_NOTICE
      cookies[:informed_sdk] = {:value => ObjectEncryptor.encrypt('8.1.8'), :expires => 1.year.from_now }
    end
  end

  def nag_user_about_payout_info
    if flash.now[:notice].blank? && current_partner.approved_publisher? &&
      (current_partner.payout_info.nil? || !current_partner.payout_info.valid?)
        flash.now[:notice] = "Please remember to <a href='/billing/payment-info'>update your W8/W9</a>."
    end
  end

  def set_recent_partners
    if current_user && current_user.can_manage_account?
      partner_ids = cookies[:recent_partners].to_s.split(';')
      partner_ids = [current_partner.id] if partner_ids.empty?
      @recent_partners = partner_ids.collect do |partner_id|
        [
          Partner.find(partner_id).name,
          make_current_partner_path(partner_id)
        ]
      end
    end
  end

  def find_app(app_id, options = {})
    redirect_on_nil = options.delete(:redirect_on_nil) { true }
    if permitted_to? :edit, :dashboard_statz
      app = App.find_by_id(app_id)
    else
      app = current_partner.apps.find_by_id(app_id)
    end
    if app.nil? && redirect_on_nil
      redirect_on_app_not_found(app_id)
    else
      app
    end
  end

  def redirect_on_app_not_found(app_id)
    path = current_partner.apps.first || new_app_path
    flash[:error] = "Couldn't find app with ID #{app_id}"
    redirect_to path
  end
end
