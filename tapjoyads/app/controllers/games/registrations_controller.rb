class Games::RegistrationsController < GamesController
  
  layout nil
  
  def new
    @gamer = Gamer.new
  end
  
  def create
    @gamer = Gamer.new do |g|
      g.email = params[:gamer][:email]
      g.password = params[:gamer][:password]
      g.referrer = params[:gamer][:referrer]
    end
    if @gamer.save
      GamesMailer.deliver_gamer_confirmation(@gamer, games_confirm_url(:token => @gamer.perishable_token))
      #redirect_to games_root_path
      render(:json => { :success => true }) and return
    else
      #render :action => :new
      render(:json => { :success =>  false }) and return
    end
  end
  
end