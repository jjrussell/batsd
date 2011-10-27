require 'test_helper'

class GamerTest < ActiveSupport::TestCase
  subject { Factory(:user) }

  context "Gamer" do
    setup do
      @gamer = Factory(:gamer)
      @gamer.gamer_profile = GamerProfile.create(:gamer => @gamer)
    end

    should "increase referral count when new gamer is referred" do
      invitation = Invitation.create(
        :gamer_id => @gamer.id,
        :channel => Invitation::FACEBOOK,
        :external_info => '0')

      new_gamer = Factory(:gamer)
      new_gamer.gamer_profile = GamerProfile.create(:facebook_id => '0', :gamer => new_gamer)
      new_gamer.referrer = invitation.encrypted_referral_id
      new_gamer.send :check_referrer

      assert_equal @gamer.id, new_gamer.referred_by
      assert_equal 1, @gamer.reload.referral_count
    end

    should "set up friendships" do
      @new_gamer = Factory(:gamer)
      @new_gamer.gamer_profile = GamerProfile.create(:facebook_id => '0', :gamer => @new_gamer)
      @referring_gamer = Factory(:gamer)
      @referring_gamer.gamer_profile = GamerProfile.create(:facebook_id => '1', :gamer => @referring_gamer)
      @stalker_gamer = Factory(:gamer)
      @stalker_gamer.gamer_profile = GamerProfile.create(:facebook_id => '2', :gamer => @stalker_gamer)

      accepted_invitation = Invitation.create(:gamer_id => @referring_gamer.id,
                                              :channel => Invitation::FACEBOOK,
                                              :external_info => '0')
      rejected_invitation = Invitation.create(:gamer_id => @stalker_gamer.id,
                                              :channel => Invitation::FACEBOOK,
                                              :external_info => '0')

      Friendship.expects(:establish_friendship).with(@new_gamer.id, @referring_gamer.id).once
      Friendship.expects(:establish_friendship).with(@referring_gamer.id, @new_gamer.id).once
      Friendship.expects(:establish_friendship).with(@stalker_gamer.id, @new_gamer.id).once
      Friendship.expects(:establish_friendship).with(@new_gamer.id, @stalker_gamer.id).never

      @new_gamer.referrer = accepted_invitation.encrypted_referral_id
      @new_gamer.send :check_referrer

      assert_equal @referring_gamer.id, @new_gamer.referred_by
      assert_equal 1, @referring_gamer.reload.referral_count
      assert_equal 0, @stalker_gamer.reload.referral_count
    end

    should "be able to deactivate" do
      @gamer.deactivate!
      assert @gamer.deactivated_at > Time.zone.now - 1.minute
      assert @gamer.deactivated_at < Time.zone.now
    end

  end
end
