class Api::ClientController < ActionController::Base
  layout "api_client"

  before_filter { raise ActionController::RoutingError.new('Not Found') } if Rails.env.production?

  # Currently passes through all permission checks
  def current_ability
    @current_ability ||= GrantAllAbility.new(nil)
  end

  class GrantAllAbility
    include CanCan::Ability

    def initialize(user)
      can :access, :all
    end
  end
end
