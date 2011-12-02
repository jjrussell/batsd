class Games::GamersController < GamesController

  before_filter :set_profile, :only => [ :edit, :accept_tos, :password, :prefs, :social, :friends, :update_password, :update_social, :confirm_delete ]
  before_filter :offline_facebook_authenticate, :only => :connect_facebook_account

  def create
    @gamer = Gamer.new do |g|
      g.email                 = params[:gamer][:email]
      g.password              = params[:gamer][:password]
      g.password_confirmation = params[:gamer][:password]
      g.referrer              = params[:gamer][:referrer]
      g.terms_of_service      = params[:gamer][:terms_of_service]
    end
    birthdate = Date.new(params[:date][:year].to_i, params[:date][:month].to_i, params[:date][:day].to_i)
    @gamer_profile = GamerProfile.new(:birthdate => birthdate)
    @gamer.gamer_profile = @gamer_profile

    if @gamer.save
      GamesMarketingMailer.deliver_gamer_confirmation(@gamer, games_confirm_url(:token => @gamer.confirmation_token))
      render(:json => { :success => true, :link_device_url => new_games_gamer_device_path, :linked => @gamer.devices.any? })
    else
      errors = @gamer.errors.reject{|error|error[0] == 'gamer_profile'}
      errors |= @gamer_profile.errors.to_a
      render(:json => { :success => false, :error => errors })
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
    @image_source_options = { 'Gravatar' => Gamer::IMAGE_SOURCE_GRAVATAR}
    if @gamer_profile.facebook_id.present?
      fb_create_user_and_client(@gamer_profile.fb_access_token, '', @gamer_profile.facebook_id)
      current_facebook_user.fetch
      @image_source_options['Facebook'] = Gamer::IMAGE_SOURCE_FACEBOOK
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

  def update_social
    @gamer.safe_update_attributes(params[:gamer], [ :image_source ])
    if @gamer.save
      redirect_to edit_games_gamer_path
    else
      flash.now[:error] = 'Error updating profile image source'
      render :action => :social
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
      render(:json => { :success => false, :error => @gamer.errors }) and return
    end
  end

  def friends
    @friends_lists = {
      :following => get_friends_info(Friendship.following_ids(current_gamer.id)),
      :followers => get_friends_info(Friendship.follower_ids(current_gamer.id))
    }
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
        :image_url => friend.get_avatar_url(80)
      }
    end
  end
end
