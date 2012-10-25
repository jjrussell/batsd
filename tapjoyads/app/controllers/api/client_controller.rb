class Api::ClientController < ActionController::Base
  before_filter { raise ActionController::RoutingError.new('Not Found') } if Rails.env.production?
end
