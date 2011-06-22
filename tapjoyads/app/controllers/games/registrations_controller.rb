class Games::RegistrationsController < GamesController
  
  def new
    @gamer = Gamer.new
  end
  
  def create
    @gamer = Gamer.new do |g|
      g.username              = params[:gamer][:username]
      g.email                 = params[:gamer][:email]
      g.password              = params[:gamer][:password]
      g.password_confirmation = params[:gamer][:password_confirmation]
      g.referrer              = params[:gamer][:referrer]
    end
    if @gamer.save
      redirect_to games_root_path
    else
      render :action => :new
    end
  end
  
end
