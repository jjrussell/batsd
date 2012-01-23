class Games::GamersController < GamesController
  rescue_from Mogli::Client::ClientException, :with => :handle_mogli_exceptions
  rescue_from Errno::ECONNRESET, :with => :handle_errno_exceptions
  rescue_from Errno::ETIMEDOUT, :with => :handle_errno_exceptions
  before_filter :set_profile, :only => [ :edit, :accept_tos, :password, :prefs, :social, :update_password, :confirm_delete ]
  before_filter :offline_facebook_authenticate, :only => :connect_facebook_account

  def create
    @gamer = Gamer.new do |g|
      g.email                 = params[:gamer][:email]
      g.password              = params[:gamer][:password]
      g.password_confirmation = params[:gamer][:password]
      g.referrer              = params[:gamer][:referrer]
      g.terms_of_service      = params[:gamer][:terms_of_service]
    end
    begin
      birthdate = Date.new(params[:date][:year].to_i, params[:date][:month].to_i, params[:date][:day].to_i)
    rescue ArgumentError => e
      if e.message == 'invalid date'
        errors = [ ['birthday', 'is not valid'] ]
        render_json_error(errors) and return
      else
        raise e
      end
    end
    @gamer_profile = GamerProfile.new(:birthdate => birthdate)
    @gamer.gamer_profile = @gamer_profile

    if @gamer.save
      params[:default_platforms] ||= []
      message = {
        :gamer_id => @gamer.id,
        :accept_language_str => request.accept_language,
        :user_agent_str => request.user_agent,
        :device_type => device_type,
        :selected_devices => params[:default_platforms].reject { |k, v| v != '1' }.keys,
        :geoip_data => get_geoip_data,
        :os_version => os_version }
      Sqs.send_message(QueueNames::SEND_WELCOME_EMAILS, Base64::encode64(Marshal.dump(message)))

      if params[:data].present? && params[:src] == 'android_app'
        render(:json => { :success => true, :link_device_url => finalize_games_gamer_device_path(:data => params[:data]), :android => true })
      else
        render(:json => { :success => true, :link_device_url => new_games_gamer_device_path })
      end
    else
      errors = @gamer.errors.reject{|error|error[0] == 'gamer_profile'}
      errors |= @gamer_profile.errors.to_a
      render_json_error(errors) and return
    end
  end

  def edit
    if @gamer_profile.country.blank?
      @geoip_data = get_geoip_data
      @gamer_profile.country = Countries.country_code_to_name[@geoip_data[:country]]
    end

    if @gamer_profile.facebook_id.present?
      fb_create_user_and_client(@gamer_profile.fb_access_token, '', @gamer_profile.facebook_id)
      current_facebook_user.fetch
    end
  end

  def social
    @friends_lists = {
      :following => get_friends_info(Friendship.following_ids(current_gamer.id)),
      :followers => get_friends_info(Friendship.follower_ids(current_gamer.id))
    }
    if @gamer_profile.facebook_id.present?
      fb_create_user_and_client(@gamer_profile.fb_access_token, '', @gamer_profile.facebook_id)
      current_facebook_user.fetch
    end
  end

  def connect_facebook_account
    redirect_to :action => :social
  end

  def update_password
    @gamer.safe_update_attributes(params[:gamer], [ :password, :password_confirmation ])
    if @gamer.save
      redirect_to edit_games_gamer_path
    else
      flash.now[:error] = 'Error updating password'
      render :action => :password
    end
  end

  def destroy
    current_gamer.deactivate!
    GamesMailer.deliver_delete_gamer(current_gamer)
    flash[:notice] = 'Your account has been deactivated and scheduled for deletion!'
    redirect_to games_logout_path
  end

  def accept_tos
    @gamer.accepted_tos_version = TAPJOY_GAMES_CURRENT_TOS_VERSION
    if @gamer.save
      render(:json => { :success => true }) and return
    else
      render_json_error(@gamer.errors) and return
    end
  end

  private

  def set_profile
    if current_gamer.present?
      @gamer = current_gamer
      @gamer_profile = @gamer.gamer_profile || GamerProfile.new(:gamer => @gamer)
      @gamer.gamer_profile = @gamer_profile
    else
      flash[:error] = "Please log in and try again. You must have cookies enabled."
      redirect_to games_root_path
    end
  end

  def get_friends_info(ids)
    Gamer.find_all_by_id(ids).map do |friend|
      {
        :id        => friend.id,
        :name      => friend.get_gamer_name,
        :image_url => friend.get_avatar_url
      }
    end
  end

  def render_json_error(errors, status = 403)
    render(:json => { :success => false, :error => errors }, :status => status)
  end
end
