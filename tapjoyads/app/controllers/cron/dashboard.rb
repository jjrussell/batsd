class Cron::Dashboard < ApplicationController
  include AuthenticationHelper
  
  before_filter 'authenticate'
  
  def index
    render :text => "hi"
  end
end