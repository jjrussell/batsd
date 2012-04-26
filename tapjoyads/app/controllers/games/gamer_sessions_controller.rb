class Games::GamerSessionsController < GamesController

  def index
    redirect_to games_login_path
  end

  def new
    if current_gamer
      redirect_to games_root_path and return
    end
    render_login_page
  end

  def create
    @gamer_session = GamerSession.new(params[:gamer_session])
    @gamer_session.remember_me = true
    if @gamer_session.save
      if current_gamer.referrer == "NEW_SIGN_UP_WITH_FACEBOOK"
        current_gamer.referrer     = params[:referrer].present? ? params[:referrer] : nil
        current_gamer.confirmed_at = current_gamer.created_at
        current_gamer.save
        default_platforms = {}
        default_platforms[params[:default_platform]] = "1" if params[:default_platform]
        current_gamer.send_welcome_email(request, device_type, default_platforms, geoip_data, os_version)

        if params[:data].present? && params[:src] == 'android_app'
          redirect_to link_device_games_gamer_path(:link_device_url => finalize_games_gamer_device_path(:data => params[:data]), :android => true) and return
        else
          redirect_to link_device_games_gamer_path(:link_device_url => new_games_gamer_device_path) and return
        end
      end

      if current_gamer.deactivated_at?
        current_gamer.reactivate!
        flash[:notice] = t('text.games.reactivated_account')
      end
      destroy and return if current_gamer.blocked?
      if params[:data].present? && cookies[:data].blank?
        redirect_to finalize_games_gamer_device_path(:data => params[:data])
      elsif params[:path]
        redirect_to params[:path]
      else
        redirect_to games_root_path
      end
    else
      render_login_page
    end
  end

  def destroy
    session[:current_device_id] = nil
    gamer_session = GamerSession.find
    gamer_session.destroy unless gamer_session.nil?
    redirect_to games_root_path
  end

end
