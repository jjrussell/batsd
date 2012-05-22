class Games::GamersController < GamesController
  rescue_from Mogli::Client::ClientException, :with => :handle_mogli_exceptions
  rescue_from Twitter::Error, :with => :handle_twitter_exceptions
  rescue_from Errno::ECONNRESET, :with => :handle_errno_exceptions
  rescue_from Errno::ETIMEDOUT, :with => :handle_errno_exceptions
  before_filter :set_profile, :only => [ :show, :edit, :accept_tos, :password, :prefs, :update_password, :confirm_delete ]

  def new
    @gamer = Gamer.new
    redirect_to games_path if current_gamer.present?
  end

  def create
    @gamer = Gamer.new do |g|
      g.nickname              = params[:gamer][:nickname]
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
    @gamer_profile = GamerProfile.new(:birthdate => birthdate, :nickname => params[:gamer][:nickname])
    @gamer.gamer_profile = @gamer_profile

    if @gamer.save
      params[:default_platforms] ||= {}
      @gamer.send_welcome_email(request, device_type, params[:default_platforms], geoip_data, os_version)

      if params[:data].present? && params[:src] == 'android_app'
        render(:json => { :success => true, :link_device_url => finalize_games_device_path(:data => params[:data]), :android => true })
      else
        render(:json => { :success => true, :link_device_url => new_games_device_path })
      end
    else
      errors = @gamer.errors.reject { |k,v| k == :gamer_profile }
      errors.merge!(@gamer_profile.errors)
      render_json_error(errors) and return
    end
  end

  def edit
    if @gamer_profile.country.blank?
      @gamer_profile.country = Countries.country_code_to_name[geoip_data[:country]]
    end

    if @gamer_profile.facebook_id.present?
      fb_create_user_and_client(@gamer_profile.fb_access_token, '', @gamer_profile.facebook_id)
      current_facebook_user.fetch
    end
  end

  def show
    @device = Device.new(:key => current_device_id) if current_device_id.present?
    @last_app = @device.present? ? ExternalPublisher.load_all_for_device(@device).first : nil;

    @friends_lists = {
      :following => get_friends_info(Friendship.following_ids(current_gamer.id)),
      :followers => get_friends_info(Friendship.follower_ids(current_gamer.id))
    }
  end


  def update_password
    @gamer.safe_update_attributes(params[:gamer], [ :password, :password_confirmation ])
    if @gamer.save
      flash[:notice] = t('text.games.password_changed')
      redirect_to games_gamer_profile_path(@gamer)
    else
      flash.now[:error] = 'Error updating password'
      render :action => :password
    end
  end

  def destroy
    current_gamer.deactivate!
    GamesMailer.delete_gamer(current_gamer).deliver
    flash[:notice] = t('text.games.scheduled_for_deletion')
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

  def create_account_for_offer
    current_facebook_user.fetch
    gamer = Gamer.find(
      :first,
      :conditions => { :gamer_profiles => { :facebook_id => current_facebook_user.id } },
      :include => :gamer_profile) ||
      Gamer.find_by_email(current_facebook_user.email) ||
      Gamer.new
    if gamer.new_record?
      gamer = Gamer.new
      gamer.before_connect(current_facebook_user)
      gamer.confirmed_at = gamer.created_at
      gamer_profile = GamerProfile.new(
        :birthdate       => current_facebook_user.birthday,
        :nickname        => current_facebook_user.name,
        :gender          => current_facebook_user.gender,
        :facebook_id     => current_facebook_user.id,
        :fb_access_token => current_facebook_user.client.access_token
      )
      gamer.gamer_profile = gamer_profile

      if gamer.save
        params[:default_platforms] ||= {}
        gamer.send_welcome_email(request, device_type, params[:default_platforms], geoip_data, os_version)
      else
        render(:json => { :success => false, :message => t('text.games.generic_issue') }) and return
      end
    else
      unless gamer.facebook_id
        attributes = {
          :facebook_id     => current_facebook_user.id,
          :fb_access_token => current_facebook_user.client.access_token
        }
        gamer.gamer_profile.update_attributes(attributes)
      end
    end

    connect_device(gamer)

    GamerSession.create(gamer)

    render(:json => { :success => true })
  end

  private

  def set_profile
    if current_gamer.present?
      @gamer = current_gamer
      @gamer_profile = @gamer.gamer_profile || GamerProfile.new(:gamer => @gamer)
      @gamer.gamer_profile = @gamer_profile
    else
      flash[:error] = "Please log in and try again. You must have cookies enabled."
      redirect_to games_path
    end
  end

  def render_json_error(errors, status = 403)
    render(:json => { :success => false, :error => errors }, :status => status)
  end

  def connect_device(gamer)
    click = Click.new(:key => Digest::MD5.hexdigest("#{params[:udid]}.#{LINK_FACEBOOK_WITH_TAPJOY_OFFER_ID}"))
    if click.rewardable?
      gamer.reward_click(click)

      gamer_device = GamerDevice.find_by_gamer_id_and_device_id(gamer.id, click.udid)
      device = Device.new :key => click.udid
      unless gamer_device
        if device.new_record?
          device.product = click.device_name
          device.save
        end
        gamer.devices.build(:device => device)
      end
      device.set_last_run_time!(LINK_FACEBOOK_WITH_TAPJOY_OFFER_ID)
    end
  end
end
