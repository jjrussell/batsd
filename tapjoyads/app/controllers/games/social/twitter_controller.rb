class Games::Social::TwitterController < GamesController
  require 'oauth'

  rescue_from OAuth::Error, :with => :handle_oauth_exceptions

  def start_oauth
    consumer = OAuth::Consumer.new(ENV['CONSUMER_KEY'], ENV['CONSUMER_SECRET'], { :site=>"http://twitter.com" })
    req_token = consumer.get_request_token(:oauth_callback => "http://#{request.host_with_port}#{games_social_twitter_finish_oauth_path}")
    session[:twitter_request_token] = req_token.token
    session[:twitter_request_token_secret] = req_token.secret
    redirect_to req_token.authorize_url
  end

  def finish_oauth
    oauth_consumer = OAuth::Consumer.new(ENV['CONSUMER_KEY'], ENV['CONSUMER_SECRET'], {:site=>"http://twitter.com" })
    req_token = OAuth::RequestToken.new(oauth_consumer, session[:twitter_request_token], session[:twitter_request_token_secret])

    if req_token
      # Request user access info from Twitter
      access_token = req_token.get_access_token

      # Store the OAuth info for the user
      authhash = {}
      access_token.token ? authhash[:twitter_id] = access_token.token.split('-')[0] : authhash[:twitter_id] = ''
      access_token.token ? authhash[:twitter_access_token] = access_token.token : authhash[:twitter_access_token] = ''
      access_token.secret ? authhash[:twitter_access_secret] = access_token.secret : authhash[:twitter_access_secret] = ''

      if authhash[:twitter_id] != '' and authhash[:twitter_access_token] != '' and authhash[:twitter_access_secret] != ''
        current_gamer.update_twitter_info!(authhash)
        redirect_to games_social_invite_twitter_friends_path
      else
        flash[:error] =  'Error while authenticating via TWITTER. The service did not return valid data.'
        redirect_to social_feature_redirect_path
      end
    else
      flash[:error] = 'Error while authenticating via TWITTER. The service did not return valid data.'
      redirect_to social_feature_redirect_path
    end
  end

  private

  def handle_oauth_exceptions(e)
    case e
    when OAuth::Unauthorized
      current_gamer.dissociate_account!(Invitation::TWITTER)
      flash[:error] = 'Please authorize us before sending out an invite.'
      redirect_to social_feature_redirect_path
    else
      flash[:error] = 'Something happened to Twttier. Please try again later.'
      redirect_to social_feature_redirect_path
    end
  end
end
