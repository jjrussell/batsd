class AgencyApi::PartnersController < AgencyApiController
  
  def create
    return unless verify_request([ :name, :email, :password ])
    
    user = User.new
    log_activity(user)
    user.username = params[:email]
    user.email = params[:email]
    user.password = params[:password]
    user.password_confirmation = params[:password]
    unless user.valid?
      render_error(user.errors, 400)
      return
    end
    
    partner = Partner.new
    log_activity(partner)
    partner.name = partner[:name]
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
    
    save_activity_logs
    render_success({ :partner_id => partner.id, :user_id => user.id, :api_key => user.api_key })
  end
  
end
