class Api::ClientController < ActionController::Base
  layout "api_client"

  before_filter { raise ActionController::RoutingError.new('Not Found') } if Rails.env.production?

  def current_user
    @current_user ||= User.find_by_id(get_access_token_info['resource_owner_id'])
  end

  def current_ability
    @current_ability ||= RoleBasedAbility.new(current_user)
  end

  private
  def get_access_token_info
    access_token = params[:access_token] || request.authorization.try(:split).try(:last)
    raise "Missing required oAuth access token" unless access_token.present?
    raise "Invalid oAuth access token" if access_token.length > 100

    key = "console.access_token.#{access_token}"
    result = Mc.get(key)  #can't do a get_and_put here, because the token info contains the expiration
    unless result.present?
      result = JSON.parse(Downloader.get("#{Rails.configuration.console_oauth_url}/oauth/token/info?access_token=#{access_token}", :timeout => 5))
      raise "oAuth token validation failed" if result['status'] == 'error'
      Mc.put(key, result, result['expires_in_seconds'].to_i.seconds)
    end
    result
  end

  class RoleBasedAbility
    include CanCan::Ability

    def initialize(user)
      can :access, :all if user.present? and user.is_admin?
    end
  end
end
