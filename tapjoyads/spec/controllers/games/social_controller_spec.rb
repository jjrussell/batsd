require 'spec_helper'

describe Games::SocialController do
  before :each do
    activate_authlogic
  end

  context "inviting facebook friends" do
    before :each do
      gamer = Factory(:gamer)
      gamer.gamer_profile = GamerProfile.create(:facebook_id => '0', :gamer => gamer)
      games_login_as(gamer)

      mogli_user = mock('mogli user')
      mogli_post = mock('mogli post')
      mogli_user.stubs(:feed_create).returns(mogli_post)
      mogli_user.stubs(:first_name).returns('f')
      mogli_user.stubs(:last_name).returns('l')
      mogli_user.stubs(:name).returns('name')
      mogli_post.stubs(:id).returns('a')
      Mogli::User.stubs(:find).returns(mogli_user)
      Mogli::Post.stubs(:new).returns(mogli_post)
      Mogli::User.any_instance.stubs(:fetch)

    end

    context "inviting friends without invitation" do
      it "returns json with gamers and non-gamers" do
        foo_gamer = Factory(:gamer)
        foo_gamer.gamer_profile = GamerProfile.create(:facebook_id => 'foo', :gamer => foo_gamer)
        friends = ['foo', 'bar']
        post 'send_facebook_invites', :friends => friends, :content => 'hello'

        should respond_with(200)
        json = JSON.load(response.body)
        json['success'].should be_true
        json['gamers'].length.should == 1
        json['non_gamers'].length.should == 1
      end
    end
  end
end
