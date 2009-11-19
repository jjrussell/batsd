class StatuszController < ApplicationController
  include AuthenticationHelper

  before_filter 'authenticate'
  
  def index
    render :text => MemcachedModel.instance.servers.to_json
  end
end
