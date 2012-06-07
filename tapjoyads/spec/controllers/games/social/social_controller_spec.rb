require 'spec_helper'

describe Games::Social::SocialController do
  before :each do
    activate_authlogic

    @gamer = Factory(:gamer, :twitter_id => '1', :twitter_access_token => 'token', :twitter_access_secret => 'secret')
    @gamer.gamer_profile = GamerProfile.create(:facebook_id => '0', :gamer => @gamer)
    login_as(@gamer)
  end

  describe '#connect_facebook_account' do
    context "when facebook account already associated with other account" do
      before :each do
        gamer2 = Factory(:gamer, :email => 'foo@test.com')
        gamer2.gamer_profile = GamerProfile.create(:facebook_id => '0', :gamer => gamer2)
        @gamer.gamer_profile.facebook_id = nil

        @current_facebook_user = mock('current_facebook_user')
        current_facebook_client = mock('current_facebook_client')
        GamesController.stub(:current_gamer).and_return(@gamer)
        GamesController.stub(:current_facebook_user).and_return(@current_facebook_user)
        @current_facebook_user.stub(:id).and_return('0')
        @current_facebook_user.stub(:current_facebook_client).and_return(current_facebook_client)
        current_facebook_client.stub(:access_token).and_return("access_token")
        get 'connect_facebook_account'
      end

      it "ensures only one tjm account associated with that Facebook account" do
        Gamer.includes(:gamer_profile).where(:gamer_profiles => { :facebook_id => @current_facebook_user.id }).count.should == 1
      end

      it "ensures current tjm account associated with that Facebook account" do
        Gamer.includes(:gamer_profile).where(:gamer_profiles => { :facebook_id => @current_facebook_user.id }).first.should == @gamer
      end
    end
  end

  describe '#send_email_invites' do
    context "when inviting friends without invitation" do
      before :each do
        foo_gamer = Factory(:gamer, :email => 'foo@test.com')
        foo_gamer.gamer_profile = GamerProfile.create(:facebook_id => 'foo', :gamer => foo_gamer)
        recipients = 'foo@test.com, bar@test.com'
        post 'send_email_invites', :recipients => recipients, :content => 'hello'
      end

      it "returns 200 as response code 200" do
        response.code.should == "200"
      end

      it "returns json with success" do
        json = JSON.load(response.body)
        json['success'].should be_true
      end

      it "returns json with gamers and non-gamers" do
        json = JSON.load(response.body)
        json['gamers'].length.should == 1
      end

      it "returns json with non-gamers" do
        json = JSON.load(response.body)
        json['non_gamers'].length.should == 1
      end
    end
  end

  describe '#send_twitter_invites' do
    before :each do
      Games::Social::TwitterController.stub(:start_oauth).and_return(@gamer)
      twitter = mock('twitter')
      twitter_user = mock('twitter user')
      twitter_msg = mock('twitter msg')
      config = mock('config')
      Twitter.stub(:direct_message_create).and_return(twitter_msg)
      Twitter.stub(:user).and_return(twitter_user)
      Twitter.stub(:configuration).and_return(config)
      config.stub(:short_url_length_https).and_return("20")
      twitter_user.stub(:name).and_return('name')
      twitter_user.stub(:screen_name).and_return('screen_name')
      twitter_user.stub(:id_str).and_return('a')
      twitter_msg.stub(:recipient).and_return(twitter_user)
      controller.stub(:twitter_authenticate)
    end

    context "when inviting friends without invitation" do
      before :each do
        foo_gamer = Factory(:gamer, :twitter_id => 'foo')
        foo_gamer.gamer_profile = GamerProfile.create(:gamer => foo_gamer)
        friends = 'foo,bar'
        post 'send_twitter_invites', :friend_selected => friends, :ajax => true
      end

      it "returns 200 as response code 200" do
        response.code.should == "200"
      end

      it "returns json with success" do
        json = JSON.load(response.body)
        json['success'].should be_true
      end

      it "returns json with gamers" do
        json = JSON.load(response.body)
        json['gamers'].length.should == 2
      end
    end
  end
end
