class Games::SocialController < GamesController
  before_filter :require_gamer
  before_filter :offline_facebook_authenticate, :only => [:invite_facebook_friends, :send_facebook_invites ]
  before_filter :validate_recipients, :only => [ :send_email_invites ]

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
      render(:json => { :success => false, :error => "You must select at least one friend before sending out an invite" })
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
          non_gamers << "#{friend.first_name} #{friend.last_name}"
          invitation = current_gamer.facebook_invitation_for(friend_id)
          if invitation.pending?
            name = TJGAMES_URL
            link = games_login_url :referrer => invitation.encrypted_referral_id
            message = "#{friend.first_name} #{friend.last_name} has invited you to join Tapjoy."
            
            description = "Experience the best of mobile apps!"
            post = Mogli::Post.new(:name => name, :link => link, :message => message, :description => description, :caption => " ", :picture => "#{TJGAMES_URL}/images/TapjoyGames_icon_114x114.jpg")
            posts << friend.feed_create(post)
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

  def invite_email_friends
    @content ="Hi,\n\n#{current_gamer.get_gamer_name} has invited you to join Tapjoy. \n\nWith Tapjoy you can discover tons of apps and build fuel in your current ones. Create your account here:\n\n#{TJGAMES_URL}\n\nStart Discovering!\nTeam Tapjoy"
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
        end

        if invitation.pending?
          link = games_login_url(:referrer => invitation.encrypted_referral_id)
          GamesMailer.deliver_invite(current_gamer.get_gamer_name, recipient, link)
        end
      end
    end
    render :json => { :success => true, :gamers => gamers, :non_gamers => non_gamers }
  end

private
  def offline_facebook_authenticate
    if current_gamer.facebook_id.blank? && params[:valid_login] && current_facebook_user
      current_gamer.gamer_profile.update_facebook_info!(current_facebook_user)
    elsif current_gamer.facebook_id?
      fb_create_user_and_client(current_gamer.fb_access_token, '', current_gamer.facebook_id)
    else
      flash[:error] = 'Please connect facebook with tapjoy games.'
      redirect_to edit_games_gamer_path
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
