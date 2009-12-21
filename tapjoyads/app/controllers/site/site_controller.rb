class Site::SiteController < ApplicationController
  include AuthenticationHelper
  before_filter :basic_authenticate
  
  private
  
  def render_not_found
    render :text => "Resource not found", :status => 404
  end
end