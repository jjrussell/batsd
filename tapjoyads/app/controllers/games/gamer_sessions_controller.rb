class Games::GamerSessionsController < GamesController
  
  def new
    @gamer_session = GamerSession.new
  end
  
  def create
    @gamer_session = GamerSession.new(params[:gamer_session])
    if @gamer_session.save
      redirect_to games_root_path
    else
      render :action => :new
    end
  end
  
  def destroy
    gamer_session = GamerSession.find
    gamer_session.destroy unless gamer_session.nil?
    redirect_to games_root_path
  end

end
