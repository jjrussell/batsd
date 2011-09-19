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
        device = Device.new :key => click.udid
        device.product = click.offer_specific_data
        device.save
        @gamer.udid = click.udid
        url = "#{API_URL}/offer_completed?click_key=#{click.key}"
        Downloader.get_with_retry url
      end
    end
    @gamer_profile = GamerProfile.new( :birthdate => Date.new(params[:date][:year].to_i, params[:date][:month].to_i, params[:date][:day].to_i) )
    @gamer.gamer_profile = @gamer_profile

    if @gamer.save
      GamesMailer.deliver_gamer_confirmation(@gamer, games_confirm_url(:token => @gamer.confirmation_token))
      render(:json => { :success => true, :link_device_url => new_games_gamer_device_path, :linked => @gamer.udid? }) and return
    else
      errors = []
      @gamer.errors.each do |error|
        errors << (error) unless error[0] == 'gamer_profile'
      end
      @gamer_profile.errors.each do |error|
        errors << (error)
      end
      render(:json => { :success => false, :error => errors }) and return
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
