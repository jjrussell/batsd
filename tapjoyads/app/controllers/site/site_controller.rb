class Site::SiteController < ApplicationController
  include AuthenticationHelper
  before_filter :basic_authenticate
  
  protected
  
  def render_not_found
    render :text => "Resource not found", :status => 404
  end
  
  def not_found(root_element)
    render :xml => {:message => "Resource not found"}.to_xml(:root => root_element), :status => 404
  end
  
  def forbidden(root_element)
    render :xml => {:message => "Forbidden access"}.to_xml(:root => root_element), :status => :forbidden
  end
  
end