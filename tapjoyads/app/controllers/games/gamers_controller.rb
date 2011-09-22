class Games::GamersController < GamesController

  before_filter :set_profile, :only => [ :edit, :password, :update_password ]

  def create
    @gamer = Gamer.new do |g|
      g.email                 = params[:gamer][:email]
      g.password              = params[:gamer][:password]
      g.password_confirmation = params[:gamer][:password]
      g.referrer              = params[:gamer][:referrer]
      g.terms_of_service      = params[:gamer][:terms_of_service]
    end
    if @gamer.referrer.starts_with?('tjreferrer:')
      click = Click.new :key => @gamer.referrer.gsub('tjreferrer:', '')
      if click.rewardable?
        @device = Device.new :key => click.udid
        @device.product = click.device_name
        @device.save
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

  def update_password
    @gamer.safe_update_attributes(params[:gamer], [ :password, :password_confirmation ])
    if @gamer.save
      redirect_to edit_games_gamer_path
    else
      flash.now[:error] = 'Error updating password'
      render :action => :password
    end
  end

private
  def set_profile
    if current_gamer.present?
      @gamer = current_gamer
    else
      flash[:error] = "Please log in and try again. You must have cookies enabled."
      redirect_to games_root_path
    end
  end
end
