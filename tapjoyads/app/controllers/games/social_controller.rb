class Games::SocialController < GamesController
  require "rubygems"
  require "twitter"
  
  before_filter :require_gamer
  before_filter :offline_facebook_authenticate, :only => [:invite_facebook_friends, :send_facebook_invites ]
  before_filter :validate_recipients, :only => [ :send_email_invites ]
  before_filter :twitter_authenticate, :only => [:invite_twitter_friends, :send_twitter_invites ]

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

      friends.each do |friend_id|
        exist_gamers = Gamer.find_all_gamer_based_on_facebook(friend_id)
        if exist_gamers.any?
          exist_gamers.each do |gamer|
            gamers << gamer.get_gamer_name
            current_gamer.follow_gamer(gamer)
          end
        else
          friend_id = DEV_FACEBOOK_ID if Rails.env != 'production'
          friend = Mogli::User.find(friend_id.to_i, current_facebook_client)
          non_gamers << friend.name
          invitation = current_gamer.invitation_for(friend_id, Invitation::FACEBOOK)
          if invitation.pending?
            name = TJGAMES_URL
            link = games_login_url :referrer => invitation.encrypted_referral_id
            message = "#{current_facebook_user.name} has invited you to join Tapjoy."

            description = "Experience the best of mobile apps!"
            post = Mogli::Post.new(:name => name, :link => link, :message => message, :description => description, :caption => " ", :picture => "#{TJGAMES_URL}/images/TapjoyGames_icon_114x114.jpg")
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
    current_facebook_user.fetch

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
          GamesMailer.deliver_invite(current_gamer.get_gamer_name, recipient, link)
        end
      end
    end
    render :json => { :success => true, :gamers => gamers, :non_gamers => non_gamers }
  end
  
  def invite_twitter_friends    
    @page_size = 25
    begin
      @twitter_complete_friends = Twitter.follower_ids.ids.map do |id|
        Twitter.user(id)
      end
    rescue Exception => e
      handle_twitter_exception(e)
      return
    end
    
    @twitter_friends = @twitter_complete_friends.map do |friend|
      {
        :twitter_id => friend.id,
        :name => friend.name,
        :image_url => friend.profile_image_url_https #profile_image_url
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
        gamer = Gamer.find_by_twitter_id(friend_id)
        if gamer
          gamers << gamer.get_gamer_name
          current_gamer.follow_gamer(gamer)
        else
          friend_name = Twitter.user(friend_id.to_i).name
          non_gamers << "#{friend_name}"
          
          friend_id = '8752692' if Rails.env != 'production'
          invitation = current_gamer.invitation_for(friend_id, Invitation::TWITTER)
          
          if invitation.pending?
            link = games_login_url :referrer => invitation.encrypted_referral_id
            link = "http://www.tapjoygames.com/games/login?referrer=#{invitation.encrypted_referral_id}" if Rails.env != 'production'
            
            message = "#{friend_name} has invited you to join Tapjoy. Experience the best of mobile apps! #{link}"
            
            begin
              # posts << Twitter.update(message)
              posts << Twitter.direct_message_create(friend_id.to_i, message) # could only send direct msg to follower
            rescue Exception => e
              handle_twitter_exception(e)
              return
            end
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
    elsif current_gamer.facebook_id?
      fb_create_user_and_client(current_gamer.fb_access_token, '', current_gamer.facebook_id)
    else
      flash[:error] = 'Please connect Facebook with Tapjoy.'
      redirect_to edit_games_gamer_path
    end
  end
  
  def twitter_authenticate
    if current_gamer.twitter_id.blank?
      redirect_to '/auth/twitter'
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
  
  def handle_twitter_exception(e)
    # TODO: more detailed error handling (based on: https://github.com/jnunemaker/twitter)
    error_code = e.message.split(/:/)[2].strip
    
    case error_code
    when '403'
      render :json => { :success => false, :error => "Please try to invite the same person again tomorrow.(Duplicate or Reach limitation)" } and return
      # flash[:error] = "Please try again tomorrow.(Duplicate or Reach limitation)"
      # redirect_to edit_games_gamer_path
      # return
    when '401'
      # render :json => { :success => false, :error => "For somereason, you\'ve revoke our app in your TWITTER, please re-authenticating us." } and return
      current_gamer.clear_twitter_info!
      redirect_to games_social_invite_twitter_friends_path
      return
    end
  end

  def require_gamer
    redirect_to games_login_path unless current_gamer
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
