class WebsiteController < ApplicationController
  include SslRequirement
  
  layout 'website'
  
  skip_before_filter :fix_params
  
  helper_method :current_user, :current_partner, :current_partner_apps, :current_partner_offers
  
  before_filter { |c| Authorization.current_user = c.current_user }

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
    @current_partner_offers ||= current_partner.offers.visible.sort_by{|app|app.name.downcase}
  end

  def sanitize_currency_params(object, fields)
    fields.each do |field|
      if object[field]
        object[field] = (object[field].gsub(/[\$,]/,'').to_f * 100).round.to_s
      end
    end
    object
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
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end
  
  def set_time_zone
    if current_user
      Time.zone = current_user.time_zone 
    else
      Time.zone = 'UTC'
    end
  end
  
end
