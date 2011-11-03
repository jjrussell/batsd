class AgencyApi::PartnersController < AgencyApiController

  def index
    return unless verify_request

    partners = @agency_user.partners.map do |partner|
      {
        :partner_id       => partner.id,
        :name             => partner.name,
        :balance          => partner.balance,
        :pending_earnings => partner.pending_earnings,
        :contact_email    => partner.contact_name,
      }
    end

    render_success({ :partners => partners })
  end

  def show
    return unless verify_request
    return unless verify_partner(params[:id])

    result = {
      :partner_id       => @partner.id,
      :name             => @partner.name,
      :balance          => @partner.balance,
      :pending_earnings => @partner.pending_earnings,
      :contact_email    => @partner.contact_name,
    }

    render_success(result)
  end

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
    partner.reseller_id = @agency_user.reseller_id
    unless partner.valid?
      render_error(partner.errors, 400)
      return
    end
    partner.save!

    user.current_partner = partner
    user.save!

    PartnerAssignment.create!(:user => user, :partner => partner)
    PartnerAssignment.create!(:user => @agency_user, :partner => partner)

    TapjoyMailer.deliver_new_secondary_account(user.email, "#{DASHBOARD_URL}/password-reset/#{user.perishable_token}/edit"

    save_activity_logs
    render_success({ :partner_id => partner.id })
  end

  def update
    return unless verify_request([ :id ])
    return unless verify_partner(params[:id])

    log_activity(@partner)
    @partner.name = params[:name] if params[:name].present?
    unless @partner.valid?
      render_error(@partner.errors, 400)
      return
    end
    @partner.save!

    save_activity_logs
    render_success
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

    PartnerAssignment.create(:user => @agency_user, :partner => user.partners.first)

    render_success({ :partner_id => user.partners.first.id })
  end

end
