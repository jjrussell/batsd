class Sales::SalesController < ApplicationController
  include AuthenticationHelper
  before_filter :sales_authenticate
  
end