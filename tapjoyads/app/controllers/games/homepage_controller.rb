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
    @device = Device.new(:key => device_id) if device_id
    @external_publishers = ExternalPublisher.load_all_for_device(@device) if @device.present?
    @featured_review = AppReview.featured_review
    #@gamer_profile = current_gamer.gamer_profile || GamerProfile.new
  end
  
  def tos
  end
  
  def privacy
  end   

private

  def require_gamer
    if current_gamer.blank?
      redirect_to games_login_path
    end
  end

end
