class Games::SocialController < GamesController
  rescue_from Errno::ECONNRESET, :with => :handle_errno_exceptions
  rescue_from Errno::ETIMEDOUT, :with => :handle_errno_exceptions

  before_filter :require_gamer
  before_filter :validate_recipients, :only => [ :send_email_invites ]

  def invite_email_friends
    @content = Invitation.invitation_message(current_gamer.get_gamer_name)
  end

  def send_email_invites
    gamers = []
    non_gamers = []

    @recipients.each do |recipient|
      gamer = Gamer.find_by_email(recipient)
      if gamer
        if gamer.email != current_gamer.email
          gamers << recipient
          gamer = Gamer.find_by_email(recipient)
          current_gamer.follow_gamer(gamer)
        end
      else
        non_gamers << recipient
        invitation = Invitation.find_by_external_info_and_gamer_id(recipient, current_gamer.id)
        if invitation.blank?
          invitation = Invitation.new({
            :gamer_id => current_gamer.id,
            :channel => Invitation::EMAIL,
            :external_info => recipient,
          })
          invitation.save

          link = params[:advertiser_app_id] == "null" ? games_login_url(:referrer => invitation.encrypted_referral_id) : games_login_url(:referrer => invitation.encrypted_referral_id(params[:advertiser_app_id]))
          GamesMarketingMailer.deliver_invite(current_gamer.get_gamer_name, recipient, link)
        end
      end
    end
    render :json => { :success => true, :gamers => gamers, :non_gamers => non_gamers }
  end

  private

  def validate_recipients
    if params[:recipients].present?
      @recipients = params[:recipients].split(/,/)
      not_valid = []

      @recipients.each_with_index do |recipient, index|
        @recipients[index] = recipient.strip.downcase
        not_valid << recipient if @recipients[index] !~ Authlogic::Regex.email
      end

      if not_valid.any?
        render :json => { :success => false, :error => "Invalid email(s):  #{not_valid.join(', ')}" }
      end
    else
      render :json => { :success => false, :error => "Please provide at least one email" }
    end
  end
end
