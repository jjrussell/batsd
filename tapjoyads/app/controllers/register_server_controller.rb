class RegisterServerController < ActionController::Base
  include AuthenticationHelper

  before_filter 'authenticate'

  def index
    new_servers = params[:servers].split(',')
    new_servers.uniq!
    CACHE.reset(new_servers)
    
    render :text => `hostname`
  end
end