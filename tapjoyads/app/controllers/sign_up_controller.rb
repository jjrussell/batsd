class SignUpController < WebsiteController

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
    @user.current_partner = Partner.new(:name => params[:partner_name] || @user.email, :contact_name => @user.email, :accepted_publisher_tos => true)
    @user.partners << @user.current_partner
    if @user.save
      flash[:notice] = 'Account successfully created.'
      TapjoyMailer.deliver_partner_signup(@user.email)
      redirect_to apps_path
    else
      render :action => :new
    end
  end

end
