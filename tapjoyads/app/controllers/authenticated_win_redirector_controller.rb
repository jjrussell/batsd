class AuthenticatedWinRedirectorController < ApplicationController
  include AuthenticationHelper

  before_filter :authenticate
  
  skip_before_filter :fix_params
  before_filter :redirect
  
  private
  
  def redirect
    # Note that this method is not fully portable, as request_uri returns different values
    # based on the server type (ie, IIS leaves it blank). This works fine for apache though.
    redirect_to 'http://winweb-lb-1369109554.us-east-1.elb.amazonaws.com' + request.request_uri
  end
end