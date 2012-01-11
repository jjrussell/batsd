class CreateAccountController < ApplicationController

  def index
    unless verify_params([ :agency_id, :email, :password, :app_name ], { :render_missing_text => false })
      error = "missing required parameters"
      render(:json => { :error => error }, :status => 400) and return
    end

    agency_user = User.find_by_id(params[:agency_id])
    unless agency_user && agency_user.role_symbols.include?(:agency)
      error = "unknown or invalid agency_id"
      render(:json => { :error => error }, :status => 404) and return
    end

    user = User.new
    user.username = params[:email]
    user.email = params[:email]
    user.password = params[:password]
    user.password_confirmation = params[:password]
    unless user.valid?
      render(:json => { :error => user.errors }, :status => 400) and return
    end

    partner = Partner.new
    partner.name = params[:email]
    partner.contact_name = params[:email]
    unless partner.valid?
      render(:json => { :error => partner.errors }, :status => 400) and return
    end
    partner.save!

    user.current_partner = partner
    user.save!

    PartnerAssignment.create!(:user => user, :partner => partner)
    PartnerAssignment.create!(:user => agency_user, :partner => partner)

    app = App.new
    app.partner = partner
    app.name = params[:app_name]
    app.platform = 'iphone'
    unless app.valid?
      render(:json => { :error => app.errors }, :status => 400) and return
    end
    app.save!

    render(:json => { :app_id => app.id })
  end

end
