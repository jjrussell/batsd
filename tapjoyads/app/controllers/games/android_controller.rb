class Games::AndroidController < GamesController

  def index
    return unless verify_params([:app_id, :udid])

    unless params[:verifier] == generate_verifier
      render :text => "invalid verifier", :status => 400 and return
    end

    data = {
      :app_id     => params[:app_id],
      :udid       => params[:udid],
      :product    => params[:device_name],
      :version    => params[:os_version],
      :platform   => params[:platform]
    }

    encrypt_data = ObjectEncryptor.encrypt(data)
    cookies[:device_type] = { :value => 'android', :expires => 1.year.from_now }
    if current_gamer.present?
      if current_gamer.devices.empty?
        redirect_to finalize_games_gamer_device_path(:data => encrypt_data, :src => 'android_app')
      else
        if valid_device_id(params[:udid])
          cookies[:data] = { :value => encrypt_data, :expires => 1.year.from_now }
          redirect_to games_path(:data => encrypt_data, :src => 'android_app')
        else
          redirect_to finalize_games_gamer_device_path(:data => encrypt_data, :src => 'android_app')
        end
      end
    else
      redirect_to games_login_path(:data => encrypt_data, :src => 'android_app')
    end
  end

end
