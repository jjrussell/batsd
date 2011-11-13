class Games::GamerSessionsController < GamesController

  def create
    @gamer_session = GamerSession.new(params[:gamer_session])
    @gamer_session.remember_me = true
    if @gamer_session.save
      destroy and return if current_gamer.blocked?
      if params[:data].present?
        redirect_to finalize_games_gamer_device_path(:data => params[:data])
      elsif params[:path]
        redirect_to params[:path]
      else
        redirect_to games_root_path
      end
    else
      show_login_form
    end
  end

  def destroy
    session[:current_device_id] = nil
    gamer_session = GamerSession.find
    gamer_session.destroy unless gamer_session.nil?
    redirect_to games_root_path
  end

end
