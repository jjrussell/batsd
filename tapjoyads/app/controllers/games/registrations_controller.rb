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
  
  def edit
    @gamer = current_gamer
  end
  
  def update
    @gamer = current_gamer
    @gamer.udid = params[:gamer][:udid]
    if @gamer.save
      redirect_to games_root_path
    else
      flash.now[:error] = 'Error updating'
      render :action => :edit
    end
  end
  
end
