require 'test_helper'

class Games::SocialControllerTest < ActionController::TestCase
  setup :activate_authlogic

  context "inviting facebook friends" do
    setup do
      @gamer = Factory(:gamer)
      @gamer.gamer_profile = GamerProfile.create(:facebook_id => '0', :gamer => @gamer)
      games_login_as(@gamer)

      mogli_user = mock('mogli user')
      mogli_post = mock('mogli post')
      mogli_user.stubs(:feed_create).returns(mogli_post)
      mogli_user.stubs(:first_name).returns('f')
      mogli_user.stubs(:last_name).returns('l')
      mogli_post.stubs(:id).returns('a')
      Mogli::User.stubs(:find).returns(mogli_user)
      Mogli::Post.stubs(:new).returns(mogli_post)

      @inviter = Factory(:gamer)
    end

    context "inviting friends without invitation" do
      should "return json with gamers and non-gamers" do
        @inviter.gamer_profile = GamerProfile.create(:facebook_id => 'foo', :gamer => @inviter)
        friends = ['foo', 'bar']
        post 'send_facebook_invites', :friends => friends, :content => 'hello'
      end
    end

    context "inviting friends with invitation" do
      should "return json with gamers and non-gamers" do
        @inviter.gamer_profile = GamerProfile.create(:facebook_id => 'bar', :gamer => @inviter)
        invitation = Factory(:invitation, :gamer => @inviter, :noob_id => @gamer.id)
        friends = ['foo', 'bar']
        post 'send_facebook_invites', :friends => friends, :content => 'hello'
      end
    end

    teardown do
      assert_response(200)
      json = JSON.load(@response.body)
      assert json['success']
      assert_equal 1, json['gamers'].length
      assert_equal 1, json['non_gamers'].length
    end
  end
end
