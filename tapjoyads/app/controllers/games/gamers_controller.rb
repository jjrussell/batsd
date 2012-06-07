class Games::GamersController < GamesController
  rescue_from Mogli::Client::ClientException, :with => :handle_mogli_exceptions
  rescue_from Twitter::Error, :with => :handle_twitter_exceptions
  rescue_from Errno::ECONNRESET, :with => :handle_errno_exceptions
  rescue_from Errno::ETIMEDOUT, :with => :handle_errno_exceptions
  before_filter :set_profile, :only => [ :show, :accept_tos, :password, :prefs, :update_password, :confirm_delete ]

  def new
    @gamer = Gamer.new
    @hide_fb_signup = UiConfig.is_fb_signup_hidden
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
      g.account_type          = params[:gamer][:account_type].to_i
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
      @gamer.send_welcome_email(request, device_type, params[:default_platforms] || {}, geoip_data, os_version)

      if params[:data].present? && params[:src] == 'android_app'
        render(:json => { :success => true, :redirect_url => link_device_games_gamer_path(:link_device_url => finalize_games_device_path(:data => params[:data]), :android => true) })
      else
        render(:json => { :success => true, :redirect_url => link_device_games_gamer_path(:link_device_url => new_games_device_path) })
      end
    else
      errors = @gamer.errors.reject { |k,v| k == :gamer_profile }
      errors.merge!(@gamer_profile.errors)
      render_json_error(errors) and return
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

  def link_device
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
end
