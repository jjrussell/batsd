class Games::ConfirmationsController < GamesController

  def create
    @gamer = Gamer.find_by_confirmation_token(params[:token])
    path   = games_root_path
    if @gamer.present? and @gamer.confirmed_at?
        flash[:notice] = 'Email address already confirmed.'
    elsif @gamer.present? and @gamer.confirm!
      flash[:notice] = 'Email address confirmed.'
      path = games_root_path(:utm_campaign => 'email_confirm',
                             :utm_medium   => 'email',
                             :utm_source   => 'tapjoy',
                             :utm_content  => params[:content]) if params[:content].present?

      if params[:content].present? && params[:content] == 'confirm_only'
        params[:default_platforms] ||= {}
        message = {
          :gamer_id => @gamer.id,
          :accept_language_str => request.accept_language,
          :user_agent_str => request.user_agent,
          :device_type => device_type,
          :selected_devices => params[:default_platforms].reject { |k, v| v != '1' }.keys,
          :geoip_data => geoip_data,
          :os_version => params[:os_version].present? ? params[:os_version] : os_version,
          :email_type => 'post_confirm' }
        Sqs.send_message(QueueNames::SEND_WELCOME_EMAILS, Base64::encode64(Marshal.dump(message)))
        Rails.logger.debug( params[:os_version])
      end
    else
      flash[:error] = 'Unable to confirm email address.'
    end
    redirect_to path
  end
end
