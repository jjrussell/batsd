class UserController < ApplicationController
  layout 'user'
  
  skip_before_filter :fix_params
  
  helper_method :current_user
  
  before_filter { |c| Authorization.current_user = c.current_user }
  
  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.record
  end
  
protected
  
  def permission_denied
    flash[:error] = "Sorry, you are not allowed to access that page."
    redirect_to user_path
  end
  
private
  
  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end
  
end
