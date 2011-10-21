class Games::HomepageController < GamesController

  before_filter :require_gamer, :except => [ :tos, :privacy ]

  def index
    @require_select_device = false
    if has_multiple_devices?
      @device_data = [] 
      current_gamer.devices.each do |d|
        data = {
          :udid         => d.device_id,
          :id           => d.id,
          :device_type  => d.device_type
        }
        device_info = {}
        device_info[:name] = d.name
        device_info[:data] = SymmetricCrypto.encrypt_object(data, SYMMETRIC_CRYPTO_SECRET)
        device_info[:device_type] = d.device_type
        @device_data << device_info
      end
      if current_device_id_cookie.nil?
        @require_select_device = true
      end
    end
    device_id = current_device_id
    device_info = current_device_info
    @device_name = device_info.name if device_info
    @device = Device.new(:key => device_id) if device_id.present?
    @external_publishers = ExternalPublisher.load_all_for_device(@device) if @device.present?
    @featured_review = AppReview.featured_review(@device.try(:platform))
  end
  
  def switch_device
    if params[:data].nil?
      redirect_to games_root_path
    elsif set_current_device(params[:data])
      cookies[:data] = { :value => params[:data], :expires => 1.year.from_now }
      redirect_to games_root_path(:switch => true)
    else
      redirect_to games_root_path(:switch => false)
    end
  end

  def tos
  end

  def privacy
  end
  
  def send_device_link
    ios_link_url = "https://#{request.host}#{games_root_path}"
    GamesMailer.deliver_link_device(current_gamer, ios_link_url, GAMES_ANDROID_MARKET_URL )
    render(:json => { :success => true }) and return
  end

private

  def require_gamer
    if current_gamer.blank?
      redirect_to games_login_path
    end
  end

end
