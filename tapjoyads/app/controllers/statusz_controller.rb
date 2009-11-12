class StatuszController < ApplicationController
  include AuthenticationHelper

  before_filter 'authenticate'
  
  def index
    render :text => CACHE.servers.to_json
  end
end
