class WebsiteController < ApplicationController
  include SslRequirement
  
  layout 'website'
  
  skip_before_filter :fix_params
  
  helper_method :current_user, :current_partner, :current_partner_apps, :current_partner_offers, :current_partner_app_offers, :current_partner_active_app_offers, :premier_enabled?
  
  before_filter { |c| Authorization.current_user = c.current_user }
  before_filter :check_employee_device

  def current_user
    @current_user ||= current_user_session && current_user_session.record
  end

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
  
  def premier_enabled?
    current_partner.exclusivity_level.present?
  end

  def check_employee_device
    return unless Rails.env == 'production'
    if current_user && current_user.employee?
      return if request.path.match(/logout|approve_device|block/)
      if device_cookie
        device = current_user.internal_devices.find_by_id(device_cookie)
        if device.approved?
          return
        elsif device.pending?
          redirect_to new_internal_device_path(:device => device.id)
        else
          redirect_bad_device
        end
      else
        redirect_to new_internal_device_path
      end
    end
  end

  def device_cookie
    @device_id ||= cookies["#{current_user.email}-device"]
    # TODO: take this block out on/after 08/25/2011
    unless @device_id
      @device_id = cookies["device"]
      if @device_id
        set_cookie( { :value => @device_id, :expires => 1.year.from_now } )
        cookies.delete("device")
      end
    end
    @device_id
    # TODO: remove to here
  end

  def set_cookie(options)
    cookies["#{current_user.email}-device"] = options
  end

protected
  
  def permission_denied
    flash[:error] = "Sorry, you are not allowed to access that page."
    redirect_to(login_path(:goto => request.path))
  end
  
  def ssl_required?
    Rails.env == 'production'
  end
  
private
  
  def current_user_session
    @current_user_session ||= UserSession.find
  end
  
  def set_time_zone
    if current_user
      Time.zone = current_user.time_zone 
    else
      Time.zone = 'UTC'
    end
  end
  
  def get_stat_prefix(group)
    @platform == 'all' ? group : "#{group}-#{@platform}"
  end

  def set_platform
    @platform = params[:platform] || 'all'
  end

  def redirect_bad_device
    flash[:error] = "Sorry, this computer has been blocked. Please contact dev@tapjoy.com if this is an error."
    UserSession.find.destroy
    redirect_to login_path
  end

  def nag_user_about_payout_info
    if current_partner.approved_publisher? && (current_partner.payout_info.nil? || !current_partner.payout_info.valid?)
      flash.now[:notice] = "Please remember to <a href='/billing/payment-info'>update your W8/W9</a>."
    end
  end
end
