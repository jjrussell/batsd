class AgencyApiController < ApplicationController
  include SslRequirement

  skip_before_filter :fix_params, :reject_banned_ips
  skip_before_filter :verify_authenticity_token

protected

  def ssl_required?
    Rails.env == 'production'
  end

private

  def render_error(error, status)
    response = { :success => false, :error => error }
    render :json => response.to_json, :status => status
  end

  def render_success(return_values = {})
    response = return_values.merge({ :success => true })
    render :json => response.to_json
  end

  def verify_request(required_params = [])
    required_params += [ :agency_id, :api_key ]

    unless verify_params(required_params, { :render_missing_text => false })
      render_error('missing required parameters', 400)
      return false
    end

    verify_agency_user
  end

  def verify_agency_user
    @agency_user = User.find_by_id(params[:agency_id], :include => :user_roles)
    verified = @agency_user.present? && @agency_user.api_key == params[:api_key] && @agency_user.role_symbols.include?(:agency)
    unless verified
      render_error('not authorized', 403)
    end
    verified
  end

  def verify_partner(partner_id)
    @partner = @agency_user.partners.find_by_id(partner_id)
    unless @partner.present?
      render_error('access denied', 403)
    end
    @partner.present?
  end

end
