class Games::Social::TwitterController < GamesController
  # callback: success
  # This handles signing in and adding an authentication service to existing accounts itself
  # It renders a separate view if there is a new user to create
  def authenticate
    # get the full hash from omniauth
    omniauth = request.env['omniauth.auth']
    
    # continue only if hash exist
    if omniauth
    
      # map the returned hashes to our variables first - the hashes differs for every service
    
      # create a new hash
      authhash = Hash.new
      omniauth['user_info']['email'] ? authhash[:twitter_email] =  omniauth['user_info']['email'] : authhash[:twitter_email] = ''
      omniauth['user_info']['name'] ? authhash[:twitter_name] =  omniauth['user_info']['name'] : authhash[:twitter_name] = ''
      omniauth['uid'] ? authhash[:twitter_id] = omniauth['uid'].to_s : authhash[:twitter_id] = ''
      omniauth['provider'] ? authhash[:provider] = omniauth['provider'] : authhash[:provider] = ''
      omniauth['credentials']['token'] ? authhash[:twitter_access_token] = omniauth['credentials']['token'] : authhash[:twitter_access_token] = ''
      omniauth['credentials']['secret'] ? authhash[:twitter_access_secret] = omniauth['credentials']['secret'] : authhash[:twitter_access_secret] = ''
      
      if authhash[:twitter_id] != '' and authhash[:twitter_access_token] != '' and authhash[:twitter_access_secret] != ''
        current_gamer.gamer_profile.update_twitter_info!(authhash)
        redirect_to games_social_invite_twitter_friends_path
      else
        flash[:error] =  'Error while authenticating via TWITTER. The service did not return valid data.'
        redirect_to edit_games_gamer_path
      end
    else
      flash[:error] = 'Error while authenticating via TWITTER. The service did not return valid data.'
      redirect_to edit_games_gamer_path
    end
  end

  # callback: failure    
  def failure
    flash[:error] = 'We need your authentication to continue inviting your twitter friends.'
    redirect_to edit_games_gamer_path
  end
end