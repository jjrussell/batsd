class Api::ClientController < ActionController::Base
  layout "api_client"

  before_filter { raise ActionController::RoutingError.new('Not Found') } if Rails.env.production?
end
