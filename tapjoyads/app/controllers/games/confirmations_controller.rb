class Games::ConfirmationsController < GamesController

  def create
    device_info = params[:data] ? ObjectEncryptor.decrypt(params[:data]) : {}
    device_info[:token] = params[:token] if params[:token]
    @gamer = Gamer.find_by_confirmation_token(device_info[:token])
    path = games_root_path
    if @gamer.present? and @gamer.confirmed_at?
        flash[:notice] = 'Email address already confirmed.'
    elsif @gamer.present? && @gamer.confirm!
      flash[:notice] = 'Email address confirmed.'
      if device_info[:content]
        path = games_root_path(:utm_campaign => 'welcome_email',
                               :utm_medium   => 'email',
                               :utm_source   => 'tapjoy',
                               :utm_content  => device_info[:content],
                               :data         => params[:data])
      end

      if device_info[:content] == 'confirm_only'
        message = {:gamer_id => @gamer.id, :email_type => 'post_confirm'}.merge(device_info)
        Sqs.send_message(QueueNames::SEND_WELCOME_EMAILS, Base64::encode64(Marshal.dump(message)))
      end
    else
      flash[:error] = 'Unable to confirm email address.'
    end
    redirect_to path
  end
end
