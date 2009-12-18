class Site::SiteController < ApplicationController
  include AuthenticationHelper
  before_filter :basic_authenticate
 
end