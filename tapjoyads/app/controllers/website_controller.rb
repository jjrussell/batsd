class WebsiteController < ApplicationController
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
    @current_partner_apps ||= current_partner.apps.visible.sort_by(&:name)
  end
  
  def current_partner_offers
    @current_partner_offers ||= current_partner.offers.visible.sort_by(&:name)
  end

protected
  
  def permission_denied
    flash[:error] = "Sorry, you are not allowed to access that page."
    redirect_to(login_path(:goto => request.path))
  end
  
private
  
  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end
  
end
