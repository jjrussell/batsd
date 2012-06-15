class Games::GamerSessionsController < GamesController
  before_filter :set_show_nav_bar_login_button, :only => [:new]

  def index
    redirect_to games_login_path
  end

  def new
    if current_gamer
      redirect_to games_path and return
    end

    set_show_partners_bar_in_footer
    render_login_page
  end

  def create
    @gamer_session = GamerSession.new(params[:gamer_session])
    @gamer_session.remember_me = true
    @gamer_session.referrer = params[:referrer] if params[:referrer].present?
    if @gamer_session.save
      if current_gamer.deactivated_at?
        current_gamer.reactivate!
        flash[:notice] = t('text.games.reactivated_account')
      end

      destroy and return if current_gamer.blocked?

      if params[:facebook]
        if current_gamer.account_type == Gamer::ACCOUNT_TYPE[:facebook_signup] && !current_gamer.confirmed_at
          current_gamer.confirm!

          @tjm_request.replace_path("tjm_facebook_signup")
          detected_platform = ''
          detected_platform = params[:platform][:detected] if params[:platform]
          current_gamer.send_welcome_email(request, device_type, detected_platform, geoip_data, os_version)
          is_android = params[:src] == 'android_app'

          render(:json => { :success => true, :new_gamer => true, :redirect_url => current_gamer.signup_next_step(params), :android_app => is_android }) and return
        else
          @tjm_request.replace_path("tjm_facebook_login")
          render(:json => { :success => true, :new_gamer => false, :redirect_url => current_gamer.signup_next_step(params), :android_app => is_android }) and return
        end
      end

      if params[:data].present? && cookies[:data].blank?
        redirect_to finalize_games_device_path(:data => params[:data])
      elsif params[:path]
        redirect_to params[:path]
      else
        redirect_to games_path
      end
    else
      flash[:error] = @gamer_session.errors.full_messages.join '\n'
      options = {}
      options[:path] = params[:path] if params[:path]
      options[:state] = 'login-focused'
      redirect_to new_games_gamer_session_path(options)
    end
  end

  def destroy
    session[:current_device_id] = nil
    gamer_session = GamerSession.find
    gamer_session.destroy unless gamer_session.nil?
    redirect_to games_path
  end

end
