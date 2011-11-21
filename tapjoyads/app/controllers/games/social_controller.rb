class Games::SocialController < GamesController
  require "rubygems"
  require "twitter"
  include ActionView::Helpers::TextHelper

  rescue_from Mogli::Client::ClientException, :with => :handle_mogli_exceptions
  rescue_from Twitter::Error, :with => :handle_twitter_exceptions
  rescue_from Errno::ECONNRESET, :with => :handle_other_exceptions
  rescue_from Errno::ETIMEDOUT, :with => :handle_other_exceptions

  before_filter :require_gamer
  before_filter :offline_facebook_authenticate, :only => [ :invite_facebook_friends, :send_facebook_invites ]
  before_filter :validate_recipients, :only => [ :send_email_invites ]
  before_filter :twitter_authenticate, :only => [:invite_twitter_friends, :send_twitter_invites ]

  def invite_facebook_friends
    current_facebook_user.fetch
    @page_size = 25
    @fb_friends = current_facebook_user.friends.map do |friend|
      {
        :social_id => friend.id,
        :name => friend.name,
        :image_url => friend.square_image_url
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
        exist_gamers = Gamer.find_all_gamer_based_on_channel(Invitation::FACEBOOK, friend_id)
        if exist_gamers.any?
          exist_gamers.each do |gamer|
            gamers << gamer.get_gamer_name
            current_gamer.follow_gamer(gamer)
          end
        else
          friend_id = DEV_FACEBOOK_ID if !Rails.env.production?
          friend = Mogli::User.find(friend_id.to_i, current_facebook_client)
          non_gamers << friend.name
          invitation = current_gamer.invitation_for(friend_id, Invitation::FACEBOOK)
          if invitation.pending?
            name = WEBSITE_URL
            link = games_login_url :referrer => invitation.encrypted_referral_id
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

          link = games_login_url(:referrer => invitation.encrypted_referral_id)
          GamesMarketingMailer.deliver_invite(current_gamer.get_gamer_name, recipient, link)
        end
      end
    end
    render :json => { :success => true, :gamers => gamers, :non_gamers => non_gamers }
  end

  def invite_twitter_friends
    @page_size = 25

    twitter_friends = Twitter.follower_ids.ids.map do |id|
      Twitter.user(id)
    end

    @twitter_friends = twitter_friends.map do |friend|
      {
        :social_id => friend.id,
        :name => friend.name,
        :image_url => friend.profile_image_url_https
      }
    end.sort_by do |friend|
      friend[:name].downcase
    end
  end
  
  def send_twitter_invites
    friends = params[:friends]

    if friends.blank?
      render(:json => { :success => false, :error => "You must select at least one friend before sending out an invite" })
    else
      posts = []
      gamers = []
      non_gamers = []

      friends.each do |friend_id|
        exist_gamers = Gamer.find_all_gamer_based_on_channel(Invitation::TWITTER, friend_id)
        if exist_gamers.any?
          exist_gamers.each do |gamer|
            gamers << gamer.get_gamer_name
            current_gamer.follow_gamer(gamer)
          end
        else
          friend_id = TEST_TWITTER_ID if Rails.env != 'production' # please make sure the TEST_TWITTER_ID is the id of one of current twitter account's followers
          friend_name = Twitter.user(friend_id.to_i).name
          non_gamers << "#{friend_name}"
          invitation = current_gamer.invitation_for(friend_id, Invitation::TWITTER)

          if invitation.pending?
            link = games_login_url :referrer => invitation.encrypted_referral_id
            link = "http://www.tapjoygames.com/login?referrer=#{invitation.encrypted_referral_id}" if Rails.env != 'production' # we need this because twitter cannot recognize IP addr as a valid url

            name = Twitter.user(current_gamer.twitter_id.to_i).name
            cookies[:twitter_short_url_len] = { :value => Twitter.configuration.short_url_length_https, :expires => 1.day.from_now } unless cookies[:twitter_short_url_len]
            rem_len = 140 - cookies[:twitter_short_url_len].to_i - name.size - 2
            template = truncate("has invited you to join Tapjoy, the BEST place to find the hottest apps. Signing up is free!", :length => rem_len)
            message = "#{name} #{template} #{link}"

            posts << Twitter.direct_message_create(friend_id.to_i, message)
          end
        end
      end

      if gamers.any? || posts.any?{|post| post.id.present? }
        render :json => { :success => true, :gamers => gamers, :non_gamers => non_gamers }
      else
        render :json => { :success => false, :error => "There was an issue with inviting your friend, please try again later" }
      end
    end
  end

private
  def offline_facebook_authenticate
    if current_gamer.facebook_id.blank? && params[:valid_login] && current_facebook_user
      current_gamer.gamer_profile.update_facebook_info!(current_facebook_user)
      unless has_permissions?
        dissociate_and_redirect
      end
    elsif current_gamer.facebook_id?
      fb_create_user_and_client(current_gamer.fb_access_token, '', current_gamer.facebook_id)
      unless has_permissions?
        dissociate_and_redirect
      end
    else
      flash[:error] = @error_msg ||'Please connect Facebook with Tapjoy.'
      redirect_to edit_games_gamer_path
    end
  end

  def twitter_authenticate
    if current_gamer.twitter_id.blank?
      redirect_to games_social_twitter_start_oauth_path #'/auth/twitter'
    elsif current_gamer.twitter_id? and current_gamer.twitter_access_token? and current_gamer.twitter_access_secret?
      Twitter.configure do |config|
        config.consumer_key       = ENV['CONSUMER_KEY']
        config.consumer_secret    = ENV['CONSUMER_SECRET']
        config.oauth_token        = current_gamer.twitter_access_token
        config.oauth_token_secret = current_gamer.twitter_access_secret
      end
    else
      flash[:error] = 'Error while authenticating via TWITTER. Please try again.'
      redirect_to edit_games_gamer_path
    end
  end

  def handle_twitter_exceptions(e)
    case e
    when Twitter::Forbidden
      render :json => { :success => false, :error => "Please try to invite the same person again tomorrow.(Duplicate or Reach limitation)" }
    when Twitter::Unauthorized
      current_gamer.dissociate_account!(Invitation::TWITTER)
      render :json => { :success => false, :error_redirect => true } and return if params[:ajax].present?
      redirect_to games_social_invite_twitter_friends_path
    when Twitter::InternalServerError, Twitter::BadGateway, Twitter::ServiceUnavailable
      render :json => { :success => false, :error => "Something happened to Twttier. Please try again later" } and return if params[:ajax].present?
      flash[:error] = 'Something happened to Twttier. Please try again later.'
      redirect_to edit_games_gamer_path
    else
      render :json => { :success => false, :error => "There was an issue with inviting your friend, please try again later" } and return if params[:ajax].present?
      flash[:error] = 'There was an issue with inviting your friend, please try again later.'
      redirect_to edit_games_gamer_path
    end
  end

  def has_permissions?
    begin
      unless current_facebook_user.has_permission?(:offline_access) && current_facebook_user.has_permission?(:publish_stream)
        @error_msg = "Please grant us both permissions before sending out an invite."
      end
    rescue
    end
    @error_msg.blank?
  end

  def dissociate_and_redirect
    current_gamer.dissociate_account!(Invitation::FACEBOOK)
    render :json => { :success => false, :error_redirect => true } and return if params[:ajax].present?
    flash[:error] = @error_msg
    redirect_to edit_games_gamer_path
  end

  def handle_mogli_exceptions(e)
    case e
    when Mogli::Client::FeedActionRequestLimitExceeded
      @error_msg = "You've reached the limit. Please try again later."
    when Mogli::Client::HTTPException
      @error_msg = "There was an issue with inviting your friend. Please try again later."
    when Mogli::Client::SessionInvalidatedDueToPasswordChange, Mogli::Client::OAuthException
      @error_msg = "Please authorize us before sending out an invite."
    else
      @error_msg = "There was an issue with inviting your friend. Please try again later."
    end

    dissociate_and_redirect
  end

  def handle_other_exceptions(e)
    case e
    when Errno::ECONNRESET, Errno::ETIMEDOUT
      @error_msg = "There was a connection issue. Please try again later."
      redirect_to edit_games_gamer_path
    end
  end

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
