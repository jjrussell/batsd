class Api::ClientController < ActionController::Base
  include SecurityControllerAdditions

  layout "api_client"

  before_filter { raise ActionController::RoutingError.new('Not Found') } if Rails.env.production?

  # Currently passes through all permission checks
  def current_ability
    @current_ability ||= SecurityControllerAdditions::GrantAllAbility.new(nil)
  end
end
