class Site::SiteController < ApplicationController
  include AuthenticationHelper

  before_filter :authenticate
 
end