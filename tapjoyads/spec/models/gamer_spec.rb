require 'spec_helper'

describe Gamer do
  before :each do
    fake_the_web
  end

  subject { Factory(:user) }

  context "Gamer" do
    before :each do
      @gamer = Factory(:gamer, :twitter_id => '1')
      @gamer.gamer_profile = GamerProfile.create(:facebook_id => '0', :gamer => @gamer)
    end

    it 'should be compatible with old invitation' do
      invitation = Invitation.create(
        :gamer_id => @gamer.id,
        :channel => Invitation::FACEBOOK,
        :external_info => '0')

      new_gamer = Factory(:gamer)
      new_gamer.gamer_profile = GamerProfile.create(:facebook_id => '0', :gamer => new_gamer)
      new_gamer.referrer = ObjectEncryptor.encrypt("#{@gamer.id},#{invitation.id}")
      new_gamer.send :check_referrer

      new_gamer.referred_by.should == @gamer.id
      Friendship.new(:key => "#{new_gamer.id}.#{@gamer.id}", :consistent => true).should_not be_new_record
    end

    it 'should set up friendships' do
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

      @new_gamer.referred_by.should == @referring_gamer.id
      @referring_gamer.reload.referral_count.should == 0
      @stalker_gamer.reload.referral_count.should == 0
    end

    it 'should be able to deactivate' do
      @gamer.deactivate!
      @gamer.deactivated_at.should > Time.zone.now - 1.minute
      @gamer.deactivated_at.should < Time.zone.now
    end

    describe '#external_info' do
      context 'when channel == Invitation::EMAIL' do
        it 'returns email' do
          @gamer.external_info(Invitation::EMAIL).should == @gamer.email
        end
      end

      context 'when channel == Invitation::FACEBOOK' do
        it 'returns facebook_id' do
          @gamer.external_info(Invitation::FACEBOOK).should == @gamer.facebook_id
        end
      end

      context 'when channel == Invitation::TWITTER' do
        it 'returns twitter_id' do
          @gamer.external_info(Invitation::TWITTER).should == @gamer.twitter_id
        end
      end
    end

    describe '.find_all_gamer_based_on_channel' do
      context 'when channel == Invitation::FACEBOOK' do
        before :each do
          @facebook_id = '2'
          gamer1 = Factory(:gamer)
          gamer1.gamer_profile = GamerProfile.create(:facebook_id => @facebook_id, :gamer => gamer1)
    
          gamer2 = Factory(:gamer)
          gamer2.gamer_profile = GamerProfile.create(:facebook_id => @facebook_id, :gamer => gamer2)
        end
        it 'returns gamers based on facebook_id' do
          Gamer.find_all_gamer_based_on_channel(Invitation::FACEBOOK, @facebook_id).size.should == 2
        end
      end

      context 'when channel == Invitation::TWITTER' do
        before :each do
          @twitter_id = '2'
          Factory(:gamer, :twitter_id => @twitter_id)
          Factory(:gamer, :twitter_id => @twitter_id)
        end
        it 'returns gamers based on twitter_id' do
          Gamer.find_all_gamer_based_on_channel(Invitation::TWITTER, @twitter_id).size.should == 2
        end
      end
    end

    describe '#follow_gamer' do
      before :each do
        @gamer2 = Factory(:gamer)
        @gamer.follow_gamer(@gamer2)
      end

      it 'establishes friendship' do
        Friendship.find_by_id("#{@gamer.id}.#{@gamer2.id}").should_not be_nil
      end
    end

    describe '#invitation_for' do
      before :each do
        @gamer2 = Factory(:gamer, :twitter_id => '2')
      end

      context 'when invitation not exist' do
        it 'creates and returns an invitation' do
          @gamer.invitation_for(@gamer2.twitter_id, Invitation::TWITTER).class.should == Invitation
        end

        it "sets invitation external_info with friend's twitter_id" do
          @gamer.invitation_for(@gamer2.twitter_id, Invitation::TWITTER).external_info.should == @gamer2.twitter_id
        end
      end

      context 'when invitation exist' do
        before :each do
          @invitation = Factory(:invitation, :gamer => @gamer, :channel => Invitation::TWITTER, :external_info => @gamer2.twitter_id)
        end
        it 'returns an invitation' do
          @gamer.invitation_for(@gamer2.twitter_id, Invitation::TWITTER).class.should == Invitation
        end

        it "returns an invitation with correct external_info" do
          @gamer.invitation_for(@gamer2.twitter_id, Invitation::TWITTER).external_info.should == @gamer2.twitter_id
        end
      end
    end

    describe '#update_twitter_info!' do
      before :each do
        @authhash = {
          :twitter_id            => '3',
          :twitter_access_token  => 'twitter_access_token',
          :twitter_access_secret => 'twitter_access_secret'
        }
        @gamer2 = Factory(:gamer)
        @gamer3 = Factory(:gamer)
        @gamer3.gamer_profile = GamerProfile.create(:gamer => @gamer3, :referred_by => @gamer.id)

        @invitation = Factory(:invitation, :gamer => @gamer, :channel => Invitation::TWITTER, :external_info => @authhash[:twitter_id], :status => Invitation::PENDING)
        @invitation2 = Factory(:invitation, :gamer => @gamer2, :channel => Invitation::TWITTER, :external_info => @authhash[:twitter_id], :status => Invitation::PENDING)
      end

      context 'when twitter_id different' do
        it 'updates twitter_id' do
          @gamer3.update_twitter_info!(@authhash)
          @gamer3.twitter_id.should == @authhash[:twitter_id]
        end

        it 'establish friendship from inviter to noob' do
          @gamer3.update_twitter_info!(@authhash)
          Friendship.find_by_id("#{@gamer.id}.#{@gamer3.id}").should_not be_nil
        end

        it 'establish friendship from other inviter to noob' do
          @gamer3.update_twitter_info!(@authhash)
          Friendship.find_by_id("#{@gamer2.id}.#{@gamer3.id}").should_not be_nil
        end

        it "updates invitations' status" do
          Invitation.expects(:reconcile_pending_invitations).with(@gamer3, :external_info => @authhash[:twitter_id])
          @gamer3.update_twitter_info!(@authhash)
        end
      end
    end

    describe '#dissociate_account!' do
      context 'when account_type == Invitation::FACEBOOK' do
        it 'empties facebook_id' do
          @gamer.dissociate_account!(Invitation::FACEBOOK)
          @gamer.facebook_id.should be_nil
        end
      end

      context 'when account_type == Invitation::TWITTER' do
        it 'empties twitter_id' do
          @gamer.dissociate_account!(Invitation::TWITTER)
          @gamer.twitter_id.should be_nil
        end
      end
    end
  end

  context "Deleting Gamers" do
    it 'should only delete users deactivated 3 days ago' do
      5.times.each { Factory(:gamer) }
      5.times.each { Factory(:gamer, :deactivated_at => Time.zone.now) }
      5.times.each { Factory(:gamer, :deactivated_at => Time.zone.now - Gamer::DAYS_BEFORE_DELETION.days - 1.day) }
      Gamer.count.should == 15
      Gamer.to_delete.each(&:destroy)
      Gamer.count.should == 10
    end

    it 'should also delete friendships' do
      gamer = Factory(:gamer, :deactivated_at => Time.zone.now - Gamer::DAYS_BEFORE_DELETION.days - 1.day)

      stalker = Factory(:gamer)

      friendship = Friendship.new
      friendship.gamer_id  = stalker.id
      friendship.following_id = gamer.id
      friendship.serial_save

      friend = Factory(:gamer)

      friendship = Friendship.new
      friendship.gamer_id  = gamer.id
      friendship.following_id = friend.id
      friendship.serial_save

      friendship = Friendship.new
      friendship.gamer_id  = friend.id
      friendship.following_id = gamer.id
      friendship.serial_save

      Friendship.count(:where => "gamer_id = '#{gamer.id}' or following_id = '#{gamer.id}'", :consistent => true).should == 3
      Gamer.to_delete.each(&:destroy)
      Friendship.count(:where => "gamer_id = '#{gamer.id}' or following_id = '#{gamer.id}'", :consistent => true).should == 0
    end

    it 'should also delete invitations' do
      gamer = Factory(:gamer, :deactivated_at => Time.zone.now - Gamer::DAYS_BEFORE_DELETION.days - 1.day)
      3.times do
        Invitation.create({
          :gamer_id => gamer.id,
          :channel => Invitation::EMAIL,
          :external_info => Factory.next(:name),
        })
      end
      Invitation.count.should == 3
      Gamer.to_delete.each(&:destroy)
      Invitation.count.should == 0
    end

    it 'should not error out when deleted invitations are fulfilled' do

      gamer = Factory(:gamer, :deactivated_at => Time.zone.now - Gamer::DAYS_BEFORE_DELETION.days - 1.day)
      invitation = Invitation.create({
        :gamer_id => gamer.id,
        :channel => Invitation::EMAIL,
        :external_info => Factory.next(:name),
      })
      referrer = invitation.encrypted_referral_id

      Gamer.to_delete.each(&:destroy)

      noob = Gamer.new do |g|
        g.email                 = 'a@tapjoy.com'
        g.password              = 'aaaa'
        g.password_confirmation = 'aaaa'
        g.referrer              = referrer
        g.terms_of_service      = '1'
      end
      noob.gamer_profile = GamerProfile.new(:birthdate => Date.parse('1981-10-23'))

      noob.save
    end
  end

end
