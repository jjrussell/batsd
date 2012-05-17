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
        GamesController.stubs(:current_gamer).returns(@gamer)
        GamesController.stubs(:current_facebook_user).returns(@current_facebook_user)
        @current_facebook_user.stubs(:id).returns('0')
        @current_facebook_user.stubs(:current_facebook_client).returns(current_facebook_client)
        current_facebook_client.stubs(:access_token).returns("access_token")
        get 'connect_facebook_account'
      end

      it "ensures only one tjm account associated with that Facebook account" do
        Gamer.count(
          :all,
          :conditions => { :gamer_profiles => { :facebook_id => @current_facebook_user.id } },
          :include => :gamer_profile
        ).should == 1
      end

      it "ensures current tjm account associated with that Facebook account" do
        Gamer.find(
          :first,
          :conditions => { :gamer_profiles => { :facebook_id => @current_facebook_user.id } },
          :include => :gamer_profile
        ).should == @gamer
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
      Games::Social::TwitterController.stubs(:start_oauth).returns(@gamer)
      twitter = mock('twitter')
      twitter_user = mock('twitter user')
      twitter_msg = mock('twitter msg')
      config = mock('config')
      Twitter.stubs(:direct_message_create).returns(twitter_msg)
      Twitter.stubs(:user).returns(twitter_user)
      Twitter.stubs(:configuration).returns(config)
      config.stubs(:short_url_length_https).returns("20")
      twitter_user.stubs(:name).returns('name')
      twitter_user.stubs(:screen_name).returns('screen_name')
      twitter_user.stubs(:id_str).returns('a')
      twitter_msg.stubs(:recipient).returns(twitter_user)
      controller.stubs(:twitter_authenticate)
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
