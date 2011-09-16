class Games::GamersController < GamesController

  def create
    @gamer = Gamer.new do |g|
      g.email            = params[:gamer][:email]
      g.password         = params[:gamer][:password]
      g.referrer         = params[:gamer][:referrer]
      g.terms_of_service = params[:gamer][:terms_of_service]
    end
    if @gamer.referrer.starts_with?('tjreferrer:')
      click = Click.new :key => @gamer.referrer.gsub('tjreferrer:', '')
      if click.rewardable?
        @gamer.udid = click.udid
        url = "#{API_URL}/offer_completed?click_key=#{click.key}"
        Downloader.get_with_retry url
      end
    end
    if @gamer.save
      GamesMailer.deliver_gamer_confirmation(@gamer, games_confirm_url(:token => @gamer.confirmation_token))
      render(:json => { :success => true, :link_device_url => new_games_gamer_device_path, :linked => @gamer.udid? }) and return
    else
      render(:json => { :success => false, :error => @gamer.errors }) and return
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
