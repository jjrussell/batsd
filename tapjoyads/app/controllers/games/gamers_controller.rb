class Games::GamersController < GamesController
  
  def new
    @gamer = Gamer.new
  end
  
  def create
    @gamer = Gamer.new do |g|
      g.email            = params[:gamer][:email]
      g.password         = params[:gamer][:password]
      g.referrer         = params[:gamer][:referrer]
      g.terms_of_service = params[:gamer][:terms_of_service]
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
  
  def start_link
    if current_gamer.present?
      respond_to do |format|
        format.mobileconfig do
          response.headers['Content-Disposition'] = "attachment; filename=TapjoyGamesProfile.mobileconfig"
          
          file = File.open('app/views/games/gamers/start_link.mobileconfig')
          render :text => file.read
        end
      end
    else
      flash[:error] = "Please log in and try again. You must have cookies enabled."
      redirect_to games_root_path
    end
  end
  
  def finish_link
    match = request.raw_post.match(/<plist.*<\/plist>/m)
    raise "Plist not present" unless match.present? && match[0].present?
    
    udid, product, version = nil
    (Hpricot(match[0])/"key").each do |key|
      value = key.next_sibling.inner_text
      case key.inner_text
      when 'UDID';    udid = value
      when 'PRODUCT'; product = value
      when 'VERSION'; version = value
      end
    end
    raise "Error parsing plist" if udid.blank? || product.blank? || version.blank?
    
    redirect_to link_games_gamer_path(:udid => udid, :product => product, :version => version), :status => 301
  rescue Exception => e
    Notifier.alert_new_relic(e.class, e.message, request, params)
    flash[:error] = "Error linking device. Please try again."
    redirect_to games_root_path, :status => 301
  end
  
  def link
    if current_gamer.present?
      current_gamer.udid = params[:udid]
      device = Device.new(:key => params[:udid])
      device.product = params[:product]
      device.version = params[:version]
      
      current_gamer.save!
      device.save
    else
      flash[:error] = "Please log in and try again. You must have cookies enabled."
    end
    redirect_to games_root_path
  end
  
end
