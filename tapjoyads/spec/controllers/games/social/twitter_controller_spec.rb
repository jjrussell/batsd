require 'spec/spec_helper'

describe Games::Social::TwitterController do
  before :each do
    activate_authlogic

    @gamer = Factory(:gamer)
    login_as(@gamer)

    @fake_consumer = mock('consumer')
    @req_token = mock('req_token')
    OAuth::Consumer.stub(:new).and_return(@fake_consumer)
    consumer = OAuth::Consumer.new('a','b',{ :site=>"http://twitter.com" })
  end

  describe '#start_oauth' do
    before :each do
      token = 'token'
      secret = 'secret'
      @authorize_url = "http://#{request.host_with_port}#{games_social_twitter_finish_oauth_path}"

      @fake_consumer.stub(:get_request_token).and_return(@req_token)
      @req_token.stub(:token).and_return(token)
      @req_token.stub(:secret).and_return(secret)
      @req_token.stub(:authorize_url).and_return(@authorize_url)

      get 'start_oauth'
    end

    context 'when success' do
      it 'redirects to games/social/twitter#finish_oauth' do
        response.should redirect_to(@authorize_url)
      end
    end
  end

  describe '#finish_oauth' do
    before :each do
      access_token = mock('access_token')
      @twitter_id = 'fake_id'
      token = "#{@twitter_id}-#{'rest_token'}"
      secret = 'secret'
      OAuth::RequestToken.stub(:new).and_return(@req_token)
      @req_token.stub(:get_access_token).and_return(access_token)
      access_token.stub(:token).and_return(token)
      access_token.stub(:secret).and_return(secret)

      get 'finish_oauth'
    end

    context 'when success' do
      it "updates gamer's twitter info" do
        @gamer.reload
        @gamer.twitter_id.should == @twitter_id
      end

      it 'redirects to games/social#invite_twitter_friends' do
        response.should redirect_to(games_social_invite_twitter_friends_path)
      end
    end
  end
end
