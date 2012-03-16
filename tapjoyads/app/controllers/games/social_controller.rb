class Games::SocialController < GamesController
  include ActionView::Helpers::TextHelper

  rescue_from Errno::ECONNRESET, :with => :handle_errno_exceptions
  rescue_from Errno::ETIMEDOUT, :with => :handle_errno_exceptions
  rescue_from Mogli::Client::ClientException, :with => :handle_mogli_exceptions
  rescue_from Twitter::Error, :with => :handle_twitter_exceptions

  before_filter :require_gamer
  before_filter :validate_recipients, :only => [ :send_email_invites ]
  before_filter :twitter_authenticate, :only => [ :send_twitter_invites, :get_twitter_friends ]
  before_filter :offline_facebook_authenticate, :only => :connect_facebook_account

  def invites
    if current_gamer.twitter_id.blank?
      @twitter_redirect_path = games_social_twitter_start_oauth_path(:advertiser_app_id => "#{params[:advertiser_app_id]}")
    else
      @twitter_redirect_path = games_social_invite_twitter_friends_path(:advertiser_app_id => "#{params[:advertiser_app_id]}")
    end
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

  def invite_twitter_friends
    @page_size = 25
  end

  def get_twitter_friends
    twitter_friends = Twitter.follower_ids.ids.map do |id|
      Twitter.user(id)
    end

    @twitter_friends = twitter_friends.map do |friend|
      {
        :social_id => friend.id,
        :name      => friend.name,
        :image_url => friend.profile_image_url_https,
        :sent      => is_sent?(Invitation::TWITTER, friend.id)
      }
    end.sort_by do |friend|
      friend[:name].downcase
    end

    render :json => {:friends => @twitter_friends, :start => 0, :selectedFriends => [], :pageSize => params[:pageSize]}, :callback => params[:callback]
  end

  def send_twitter_invites
    friends = params[:friend_selected].split(',')

    if friends.blank?
      render(:json => { :success => false, :error => t('text.games.twitter_at_least_one_friend_error') })
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
          friend_name = Twitter.user(friend_id.to_i).name
          non_gamers << friend_name
          invitation = current_gamer.invitation_for(friend_id, Invitation::TWITTER)

          if invitation.pending?
            referrer_value = params[:advertiser_app_id] == "null" ? invitation.encrypted_referral_id : invitation.encrypted_referral_id(params[:advertiser_app_id])
            link = games_login_url :referrer => referrer_value
            link = "http://www.tapjoygames.com/login?referrer=#{referrer_value}" if Rails.env != 'production' # we need this because twitter cannot recognize IP addr as a valid url

            name = Twitter.user(current_gamer.twitter_id.to_i).name
            cookies[:twitter_short_url_len] ||= {
              :value => Twitter.configuration.short_url_length_https,
              :expires => 1.day.from_now
            }
            rem_len = 140 - cookies[:twitter_short_url_len].to_i - name.size - 2
            template = truncate(t('text.games.twitter_invite_msg'), :length => rem_len)
            message = "#{name} #{template} #{link}"

            posts << Twitter.direct_message_create(friend_id.to_i, message)
          end
        end
      end

      if gamers.any? || posts.any?
        render :json => { :success => true, :gamers => gamers, :non_gamers => non_gamers }
      else
        render :json => { :success => false, :error => t('text.games.social_invite_friend_error') }
      end
    end
  end

  private

  def twitter_authenticate
    if current_gamer.require_twitter_authenticate?
      render :json => { :success => false, :errorRedirectPath => games_social_twitter_start_oauth_path } and return if params[:ajax].present?
      redirect_to games_social_twitter_start_oauth_path
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
        render :json => { :success => false, :error => t('text.games.invalid_emails') }
      end
    else
      render :json => { :success => false, :error => t('text.games.provide_one_email') }
    end
  end

  def is_sent?(channel, external_info)
    Invitation.by_channel(channel).find_by_gamer_id_and_external_info(current_gamer.id, external_info).present?
  end
end
