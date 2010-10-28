class UsersController < WebsiteController
  layout 'tabbed'
  current_tab :account
  
  filter_access_to :all
  
  after_filter :save_activity_logs, :only => [ :create, :update ]
  around_filter :update_mail_chimp_email, :only => [ :update ]

  def index
    @users = current_partner.users
    # disabled until one_offs runs
    # mail_chimp_id = MailChimp.lookup_user(current_user.email)["id"]
    # @mail_chimp_url = "http://tapjoy.us2.list-manage.com/profile?u=#{MAIL_CHIMP_SETTINGS_KEY}&id=#{MAIL_CHIMP_PARTNERS_LIST_ID}&e=#{mail_chimp_id}"
  end
  
  def new
    @user = User.new
  end
  
  def create
    @user = User.new
    log_activity(@user)
    
    @user.username = params[:user][:email]
    @user.email = params[:user][:email]
    pwd = UUIDTools::UUID.random_create.to_s
    @user.password = pwd
    @user.password_confirmation = pwd
    @user.current_partner = current_partner
    @user.partners << current_partner
    if @user.save
      TapjoyMailer.deliver_new_secondary_account(@user.email, edit_password_reset_url(@user.perishable_token))
      flash[:notice] = 'Account successfully created.'
      redirect_to users_path
    else
      render :action => :new
    end
  end
  
  def edit
    @user = current_user
  end
  
  def update
    @user = current_user
    log_activity(@user)
    
    params[:user][:username] = params[:user][:email]
    if @user.safe_update_attributes(params[:user], [ :username, :email, :password, :password_confirmation, :time_zone ])
      flash[:notice] = 'Successfully updated account.'
      redirect_to users_path
    else
      render :action => :edit
    end
  end

  private
  def update_mail_chimp_email
    email = current_user.email
    yield
    if email != current_user.email
      message = {
        :type => "update",
        :email => email,
        :field => 'EMAIL',
        :new_value => current_user.email }.to_json
      Sqs.send_message(QueueNames::MAIL_CHIMP_UPDATES, message)
    end
  end
end
