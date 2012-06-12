class Games::ConfirmationsController < GamesController

  def create
    # remove non-base64 chars (we encountered a SendGrid issue where they were adding a '+' aka space, in the url)
    # see http://en.wikipedia.org/wiki/Base64
    params[:data].gsub!(/[^A-Za-z0-9+\/]/, '') if params[:data].present?

    data = params[:data] ? ObjectEncryptor.decrypt(params[:data]) : {}
    data[:token] = params[:token] if params[:token]
    @gamer = Gamer.find_by_confirmation_token(data[:token])
    path = games_root_path
    if @gamer.present? and @gamer.confirmed_at?
        flash[:notice] = 'Email address already confirmed.'
    elsif @gamer.present? && @gamer.confirm!
      flash[:notice] = 'Email address confirmed.'
      if data[:content]
        path = games_root_path(:utm_campaign => 'welcome_email',
                               :utm_medium   => 'email',
                               :utm_source   => 'tapjoy',
                               :utm_content  => data[:content]
                               )
      end

      if data[:content] == 'confirm_only'
        message = {:gamer_id => @gamer.id, :email_type => 'post_confirm'}.merge(data)
        Sqs.send_message(QueueNames::SEND_WELCOME_EMAILS, Base64::encode64(Marshal.dump(message)))
      end
    else
      flash[:error] = 'Unable to confirm email address.'
    end
    redirect_to path
  end

  def redirect
    short_url = ShortUrl.find_by_token(params[:token])
    redirect_to short_url.long_url and return if short_url.present?
    redirect_to games_confirm_path(:token => params[:token])
  end
end
