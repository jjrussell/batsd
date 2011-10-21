class Games::AndroidController < GamesController
  
  def index
    return unless verify_params([:app_id, :udid])
    
    hash_bits = [
      params[:app_id],
      params[:udid],
      params[:timestamp],
      App.find_in_cache(params[:app_id]).secret_key
    ]
    generated_key = Digest::SHA256.hexdigest(hash_bits.join(':'))
    
    unless params[:verifier] == generated_key
      render :text => "invalid verifier", :status => 400 and return
    end
    
    data = {
      :app_id     => params[:app_id],
      :udid       => params[:udid],
      :product    => params[:device_name],
      :version    => params[:os_version],
      :platform   => params[:platform]
    }
    
    if current_gamer.present?
      if current_gamer.devices.empty?
        redirect_to finalize_games_gamer_device_path(:data => SymmetricCrypto.encrypt_object(data, SYMMETRIC_CRYPTO_SECRET), :src => 'android_app')
      else
        encypt_data = SymmetricCrypto.encrypt_object(data, SYMMETRIC_CRYPTO_SECRET)
        cookies[:data] = { :value => encypt_data, :expires => 1.year.from_now } if params[:data].present?
        redirect_to games_root_path(:data => encypt_data, :src => 'android_app')
      end
    else
      if cookies[:data].present?
        redirect_to games_login_path(:src => 'android_app')
      else
        encypt_data = SymmetricCrypto.encrypt_object(data, SYMMETRIC_CRYPTO_SECRET)
        cookies[:data] = { :value => encypt_data, :expires => 1.year.from_now } if params[:data].present?
        redirect_to games_login_path(:data => encypt_data, :src => 'android_app')
      end
    end
  end

end
