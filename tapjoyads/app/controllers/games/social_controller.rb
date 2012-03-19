class Games::SocialController < GamesController
  rescue_from Errno::ECONNRESET, :with => :handle_errno_exceptions
  rescue_from Errno::ETIMEDOUT, :with => :handle_errno_exceptions
  rescue_from Mogli::Client::ClientException, :with => :handle_mogli_exceptions

  before_filter :require_gamer
  before_filter :validate_recipients, :only => [ :send_email_invites ]
  before_filter :offline_facebook_authenticate, :only => :connect_facebook_account

  def invites
  end

  def friends
    @is_following = params[:following].present?

    friends_key = @is_following ? Friendship.following_ids(@current_gamer.id) : Friendship.follower_ids(@current_gamer.id)
    @friends_list = Gamer.find_all_by_id(friends_key)
  end

  def index
    @gamer_profile = current_gamer.gamer_profile
    @friends_lists = {
      :following => Gamer.find_all_by_id(Friendship.following_ids(@current_gamer.id)),
      :followers => Gamer.find_all_by_id(Friendship.follower_ids(@current_gamer.id))
    }
  end

  def connect_facebook_account
    flash[:notice] = t 'text.games.connected_to_facebook'
    redirect_to games_social_index_path
  end

  def invite_email_friends
    @gamer_name = current_gamer.get_gamer_name
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
        render :json => { :success => false, :error => t('text.games.invalid_emails') }
      end
    else
      render :json => { :success => false, :error => t('text.games.provide_one_email') }
    end
  end
end
