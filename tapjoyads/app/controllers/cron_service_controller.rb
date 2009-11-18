class Service1Controller < ApplicationController
  
  before_filter :redirect
  
  private
  
  def redirect
    ruby_lb = REDIRECT_URI
    win_lb = 'http://winweb-lb-1369109554.us-east-1.elb.amazonaws.com/CronService.asmx'
    redirect_to  win_lb + "/" + params[:action] + "?" + request.query_string
  end
end