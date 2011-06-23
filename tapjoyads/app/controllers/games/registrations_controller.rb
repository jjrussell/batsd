class Games::RegistrationsController < GamesController
  
  def new
    @gamer = Gamer.new
  end
  
  def create
    @gamer = Gamer.new do |g|
      g.email    = params[:gamer][:email]
      g.password = params[:gamer][:password]
      g.referrer = params[:gamer][:referrer]
    end
    if @gamer.save
      GamesMailer.deliver_gamer_confirmation(@gamer, games_confirm_url(:token => @gamer.perishable_token))
      redirect_to games_root_path
    else
      render :action => :new
    end
  end
  
end
