class AppRedirController < ApplicationController
  
  before_filter :redirect
  
  private
  
  def redirect
    win_lb = 'http://winweb-lb-1369109554.us-east-1.elb.amazonaws.com/AppRedir.aspx'
    redirect_to  win_lb + "?" + request.query_string
  end
end