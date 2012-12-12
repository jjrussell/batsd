class Dashboard::DashboardController < ApplicationController
  include SslRequirement
  include FlashMessageHelper

  layout 'website'

  skip_before_filter :fix_params
  skip_before_filter :force_utc

  helper_method :current_user, :current_partner, :current_partner_apps, :current_partner_offers, :current_partner_app_offers, :current_partner_active_app_offers, :current_partner_active_offers, :premier_enabled?, :update_flash_error_message

  before_filter { ActiveRecordDisabler.enable_queries! } unless Rails.env.production?
  before_filter { |c| Authorization.current_user = c.send(:current_user) }
  before_filter :check_employee_device
  before_filter :set_recent_partners
  before_filter :set_default_notice
  around_filter :set_time_zone

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

  def current_partner_apps_relation
    current_partner.apps.visible.order("UPPER(name)").includes(:partner)
  end

  def current_partner_apps
    @current_partner_apps ||= current_partner_apps_relation.all
  end

  def current_partner_offers_relation
    current_partner.offers.visible.order("UPPER(name), UPPER(name_suffix)").includes(:partner)
  end

  def current_partner_offers
    @current_partner_offers ||= current_partner_offers_relation.all
  end

  def current_partner_app_offers_relation
    current_partner.offers.visible.app_offers.order("UPPER(name)").includes(:partner)
  end

  def current_partner_app_offers
    @current_partner_app_offers ||= current_partner_app_offers_relation.all
  end

  def current_partner_active_app_offers
    @current_partner_active_app_offers ||= current_partner_app_offers.select(&:enabled?)
  end

  def current_partner_active_offers_relation
    # This logic is duplicated in Offer#show_in_active_campaigns? in a non-ARel-y way.
    current_partner_offers_relation.where(:item_type => ['VideoOffer', 'App', 'GenericOffer', 'ActionOffer', 'Coupon', 'SurveyOffer']).includes(:item)
  end

  def current_partner_active_offers
    @current_partner_active_offers ||= current_partner_active_offers_relation.select(&:enabled?)
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

  def product_notice
    @product_notice ||= ProductNotice.most_recent
  end

  def set_default_notice
    flash.now[:notice] = product_notice.to_s if (current_user && flash.now[:notice].blank? && product_notice.present?)
  end

  def nag_user_about_payout_info
    if flash.now[:notice].blank? && current_partner.approved_publisher? &&
      (current_partner.payout_info.nil? || !current_partner.payout_info.valid?)
        flash.now[:notice] = "Please remember to <a href='/billing/payment-info'>update your W8/W9</a>."
    end
  end

  def set_recent_partners
    if current_user && current_user.can_manage_account?
      partner_ids = cookies[:recent_partners].to_s.split(';') + current_user.partners.map(&:id)
      @recent_partners = Partner.where(:id => partner_ids.uniq).map do |partner|
        [partner.name, make_current_partner_path(partner.id)]
      end.sort
    end
  end

  def find_app(app_id, options = {})
    redirect_on_nil = options.delete(:redirect_on_nil) { true }
    if permitted_to? :edit, :dashboard_statz
      app = App.find_by_id(app_id)
    elsif current_partner.present?
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

  def all_android_store_options
    options = {}
    AppStore::SDK_STORE_NAMES.each do |k, v|
      options[AppStore.find(v).name] = k
    end
    options
  end
end
