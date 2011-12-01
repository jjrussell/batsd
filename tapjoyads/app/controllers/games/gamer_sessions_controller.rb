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
      if current_gamer.deactivated_at?
        current_gamer.reactivate!
        flash[:notice] = 'Your account has been reactivated!'
      end
      destroy and return if current_gamer.blocked?
      if params[:data].present?
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
