class AgencyApi::PartnersController < AgencyApiController
  
  def create
    return unless verify_request([ :name, :email ])
    
    user = User.new
    log_activity(user)
    user.username = params[:email]
    user.email = params[:email]
    tmp_password = UUIDTools::UUID.random_create.to_s
    user.password = tmp_password
    user.password_confirmation = tmp_password
    unless user.valid?
      render_error(user.errors, 400)
      return
    end
    
    partner = Partner.new
    log_activity(partner)
    partner.name = params[:name]
    partner.contact_name = params[:email]
    unless partner.valid?
      render_error(partner.errors, 400)
      return
    end
    partner.save!
    
    user.current_partner = partner
    user.save!
    
    PartnerAssignment.create!(:user => user, :partner => partner)
    PartnerAssignment.create!(:user => @agency_user, :partner => partner)
    
    TapjoyMailer.deliver_new_secondary_account(user.email, edit_password_reset_url(user.perishable_token))
    
    save_activity_logs
    render_success({ :partner_id => partner.id, :user_id => user.id, :api_key => user.api_key })
  end
  
  def link
    return unless verify_request([ :email, :user_api_key ])
    
    user = User.find_by_email(params[:email])
    unless user.present?
      render_error('user not found', 400)
      return
    end
    
    unless user.api_key == params[:user_api_key]
      render_error('invalid api_key for user', 403)
      return
    end
    
    unless user.partners.size == 1
      render_error('ambiguous partner', 400)
      return
    end
    
    PartnerAssignment.create!(:user => @agency_user, :partner => user.partners.first)
    
    render_success({ :user_id => user.id, :api_key => user.api_key, :partner_id => user.partners.first.id })
  end
  
end
