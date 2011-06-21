class Games::RegistrationsController < GamesController
  
  def new
    @gamer = Gamer.new
  end
  
  def create
    @gamer = Gamer.new(params[:gamer])
    if @gamer.save
      redirect_to games_root_path
    else
      render :action => :new
    end
  end
  
end
