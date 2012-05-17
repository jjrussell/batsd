class Dashboard::SignUpController < Dashboard::DashboardController

  def new
    redirect_to users_path if current_user
    @zones = {}
    ActiveSupport::TimeZone.us_zones.each do |zone|
      @zones[- zone.utc_offset / 60] = zone.name
    end
    @user = User.new
  end

  def create
    @user = User.new
    @user.username = @user.email = params[:user][:email]
    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]
    @user.terms_of_service = params[:user][:terms_of_service]
    @user.time_zone = params[:user][:time_zone]
    @user.country = params[:user][:country]
    @user.current_partner = Partner.new(:name => params[:partner_name] || @user.email, :contact_name => @user.email, :accepted_publisher_tos => true)
    @user.partners << @user.current_partner

    @user.account_type = []
    @user.account_type << 'advertiser' if params[:account_type_advertiser] == '1'
    @user.account_type << 'publisher' if params[:account_type_publisher] == '1'

    if @user.save
      flash[:notice] = 'Account successfully created.'
      TapjoyMailer.partner_signup(@user.email).deliver
      redirect_to apps_path
    else
      render :action => :new
    end
  end

  def welcome
  end
end
