class Games::GamerSessionsController < GamesController

  def index
    redirect_to games_login_path
  end

  def new
    @gamer_session = GamerSession.new
    @gamer = Gamer.new
  end

  def create
    @gamer_session = GamerSession.new(params[:gamer_session])
    @gamer_session.remember_me = true
    if @gamer_session.save
      destroy and return if current_gamer.blocked?
      if params[:data].present?
        redirect_to finalize_games_gamer_device_path(:data => params[:data])
      elsif params[:original_url]
        redirect_to params[:original_url]
      else
        redirect_to games_root_path
      end
    else
      @gamer = Gamer.new
      render :action => :new
    end
  end

  def destroy
    session[:current_device_id] = nil
    gamer_session = GamerSession.find
    gamer_session.destroy unless gamer_session.nil?
    redirect_to games_root_path
  end

end
