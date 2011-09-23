class GamesController < ApplicationController
  include SslRequirement
  
  layout 'games'
  
  skip_before_filter :fix_params
  
  helper_method :current_gamer, :current_device_id
  
  def current_gamer
    @current_gamer ||= current_gamer_session && current_gamer_session.record
  end
  
  def current_device_id
    session[:current_device_id] ||= current_gamer.devices.first.device_id
  end
  
protected
  
  def ssl_required?
    Rails.env == 'production'
  end
  
private
  
  def current_gamer_session
    @current_gamer_session ||= GamerSession.find
  end
  
end
