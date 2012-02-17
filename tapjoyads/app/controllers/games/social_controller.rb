class Games::SocialController < GamesController
  rescue_from Mogli::Client::ClientException, :with => :handle_mogli_exceptions
  rescue_from Errno::ECONNRESET, :with => :handle_errno_exceptions
  rescue_from Errno::ETIMEDOUT, :with => :handle_errno_exceptions

  before_filter :require_gamer
  before_filter :offline_facebook_authenticate, :only => [ :invite_facebook_friends, :send_facebook_invites ]
  before_filter :validate_recipients, :only => [ :send_email_invites ]

  def index
  end

  def invite_facebook_friends
    current_facebook_user.fetch
    @page_size = 25
    @fb_friends = current_facebook_user.friends.map do |friend|
      {
        :fb_id => friend.id,
        :name => friend.name
      }
    end.sort_by do |friend|
      friend[:name].downcase
    end
  end

  def send_facebook_invites
    friends = params[:friends]

    if friends.blank?
      render(:json => { :success => false, :error => "Please select at least one friend before sending out an invite" })
    else
      posts = []
      gamers = []
      non_gamers = []

      current_facebook_user.fetch

      friends.each do |friend_id|
        exist_gamers = Gamer.find_all_gamer_based_on_facebook(friend_id)
        if exist_gamers.any?
          exist_gamers.each do |gamer|
            gamers << gamer.get_gamer_name
            current_gamer.follow_gamer(gamer)
          end
        else
          friend_id = DEV_FACEBOOK_ID if !Rails.env.production?
          friend = Mogli::User.find(friend_id.to_i, current_facebook_client)
          non_gamers << friend.name
          invitation = current_gamer.facebook_invitation_for(friend_id)
          if invitation.pending?
            name = WEBSITE_URL
            link = params[:advertiser_app_id] == "null" ? games_login_url(:referrer => invitation.encrypted_referral_id) : games_login_url(:referrer => invitation.encrypted_referral_id(params[:advertiser_app_id]))
            message = "#{current_facebook_user.name} has invited you to join Tapjoy, the BEST place to find the hottest new apps. Signing up is free and you'll be able discover the best apps on iOS and Android, while also earning currency in your favorite apps."

            description = "Experience the best of mobile apps!"
            post = Mogli::Post.new(:name => name, :link => link, :message => message, :description => description, :caption => " ", :picture => "#{WEBSITE_URL}/images/ic_launcher_96x96.png")
            posts << friend.feed_create(post)
          end
        end
      end

      if gamers.any? || posts.any?{|post| post.id.present? }
        render :json => { :success => true, :gamers => gamers, :non_gamers => non_gamers }
      else
        render :json => { :success => false, :error => "There was an issue with inviting your friend. Please try again later" }
      end
    end
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
        render :json => { :success => false, :error => "Invalid email(s):  #{not_valid.join(', ')}" }
      end
    else
      render :json => { :success => false, :error => "Please provide at least one email" }
    end
  end
end
