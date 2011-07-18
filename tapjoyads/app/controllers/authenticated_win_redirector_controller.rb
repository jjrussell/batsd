# TO REMOVE: this controller when we shut down rackspace
class AuthenticatedWinRedirectorController < ApplicationController
  include AuthenticationHelper

  before_filter :authenticate
  
  skip_before_filter :fix_params
  before_filter :redirect
  
  private
  
  def redirect
    # Note that this method is not fully portable, as request_uri returns different values
    # based on the server type (ie, IIS leaves it blank). This works fine for apache though.
    redirect_to 'http://www.tapjoyconnect.com.asp1-3.dfw1-1.websitetestlink.com' + request.request_uri
  end
end