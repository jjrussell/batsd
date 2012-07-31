class Games::ConfirmationsController < GamesController

  def create
    path = games_root_path

    begin
      if params[:data].present?
        # remove non-base64 chars (we encountered a SendGrid issue where they were adding a '+' aka space, in the url)
        # see http://en.wikipedia.org/wiki/Base64
        params[:data].gsub!(/[^A-Za-z0-9+\/]/, '')
        data = ObjectEncryptor.decrypt(params[:data])
        token = data[:token]
      else
        data = EmailConfirmData.get(params[:token]) or {}
        token = params[:token]
      end

      @gamer = Gamer.find_by_confirmation_token(token)
      if @gamer.present? and @gamer.confirmed_at?
        flash[:notice] = 'Email address already confirmed.'
      elsif @gamer.present? && @gamer.confirm!
        flash[:notice] = 'Email address confirmed.'
        if data[:content]
          path = games_root_path(:utm_campaign => 'welcome_email',
                                 :utm_medium   => 'email',
                                 :utm_source   => 'tapjoy',
                                 :utm_content  => data[:content],
                                 :data         => params[:data])
        end

        if data[:content] == 'confirm_only'
          message = {:gamer_id => @gamer.id, :email_type => 'post_confirm'}.merge(data)
          Sqs.send_message(QueueNames::SEND_WELCOME_EMAILS, Base64::encode64(Marshal.dump(message)))
        end
      else
        flash[:error] = 'Unable to confirm email address.'
      end
    rescue
      flash[:error] = 'Unable to confirm email address. For troubleshooting, please forward the confirmation email to feedback@tapjoy.com'
    end
    redirect_to path
  end
end
