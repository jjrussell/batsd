class RegisterServerController < ActionController::Base
  include AuthenticationHelper

  before_filter 'authenticate'

  def index
    new_server = params[:server]
    
    servers = CACHE.servers
    servers.push(params[:server])
    servers.uniq!
    CACHE.reset(servers)
    
    render :text => `hostname`
  end
end