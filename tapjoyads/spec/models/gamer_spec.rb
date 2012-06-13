require 'spec_helper'

describe Gamer do
  subject { FactoryGirl.create(:user) }

  context "Gamer" do
    before :each do
      @gamer = FactoryGirl.create(:gamer, :twitter_id => '1')
      @gamer.gamer_profile = GamerProfile.create(:facebook_id => '0', :gamer => @gamer)
    end

    context 'suspicious activities' do
      before :each do
        @queue = QueueNames::SUSPICIOUS_GAMERS
        @json = { :gamer_id => @gamer.id }
      end

      context 'when referral count > 50' do
        before :each do
          @threshold_count = Gamer::MAX_REFERRAL_THRESHOLD
          @json[:behavior_type]   = 'referral_count'
          @json[:behavior_result] = @threshold_count
        end

        it 'should alert suspicious behavior' do
          Sqs.should_receive(:send_message).with(@queue, @json.to_json)
          @gamer.gamer_profile.update_attributes(:referral_count => @threshold_count)
        end

        context 'when gamer has already been blocked' do
          it 'should not alert suspicious behavior' do
            @gamer.update_attributes(:blocked => true)
            Sqs.should_receive(:send_message).never
            @gamer.gamer_profile.update_attributes(:referral_count => @threshold_count)
          end
        end
      end

      context 'when devices count > 15' do
        before :each do
          threshold_count = Gamer::MAX_DEVICE_THRESHOLD
          @json[:behavior_type]   = 'devices_count'
          @json[:behavior_result] = threshold_count
          (threshold_count - 1).times do
            options = {
              :device_id => FactoryGirl.generate(:guid),
              :name => FactoryGirl.generate(:name),
            }
            @gamer.gamer_devices.build(options).save
          end
        end

        it 'should alert suspicious behavior' do
          Sqs.should_receive(:send_message).with(@queue, @json.to_json)
          options = {
            :device_id => FactoryGirl.generate(:guid),
            :name => FactoryGirl.generate(:name),
          }
          @gamer.gamer_devices.build(options).save
        end

        context 'when gamer has already been blocked' do
          it 'should not alert suspicious behavior' do
            @gamer.update_attributes(:blocked => true)
            Sqs.should_receive(:send_message).never
            options = {
              :device_id => FactoryGirl.generate(:guid),
              :name => FactoryGirl.generate(:name),
            }
            @gamer.gamer_devices.build(options).save
          end
        end
      end
    end
    it 'is compatible with old invitation' do
      invitation = Invitation.create(
        :gamer_id => @gamer.id,
        :channel => Invitation::FACEBOOK,
        :external_info => '0')

      new_gamer = FactoryGirl.create(:gamer)
      new_gamer.gamer_profile = GamerProfile.create(:facebook_id => '0', :gamer => new_gamer)
      new_gamer.referrer = ObjectEncryptor.encrypt("#{@gamer.id},#{invitation.id}")
      new_gamer.send :check_referrer

      new_gamer.referred_by.should == @gamer.id
      Friendship.new(:key => "#{new_gamer.id}.#{@gamer.id}", :consistent => true).should_not be_new_record
    end

    it 'sets up friendships' do
      @new_gamer = FactoryGirl.create(:gamer)
      @new_gamer.gamer_profile = GamerProfile.create(:facebook_id => '0', :gamer => @new_gamer)
      @referring_gamer = FactoryGirl.create(:gamer)
      @referring_gamer.gamer_profile = GamerProfile.create(:facebook_id => '1', :gamer => @referring_gamer)
      @stalker_gamer = FactoryGirl.create(:gamer)
      @stalker_gamer.gamer_profile = GamerProfile.create(:facebook_id => '2', :gamer => @stalker_gamer)

      accepted_invitation = Invitation.create(:gamer_id => @referring_gamer.id,
                                              :channel => Invitation::FACEBOOK,
                                              :external_info => '0')
      rejected_invitation = Invitation.create(:gamer_id => @stalker_gamer.id,
                                              :channel => Invitation::FACEBOOK,
                                              :external_info => '0')

      Friendship.should_receive(:establish_friendship).with(@new_gamer.id, @referring_gamer.id).once
      Friendship.should_receive(:establish_friendship).with(@referring_gamer.id, @new_gamer.id).once
      Friendship.should_receive(:establish_friendship).with(@stalker_gamer.id, @new_gamer.id).once
      Friendship.should_receive(:establish_friendship).with(@new_gamer.id, @stalker_gamer.id).never

      @new_gamer.referrer = accepted_invitation.encrypted_referral_id
      @new_gamer.send :check_referrer

      @new_gamer.referred_by.should == @referring_gamer.id
      @referring_gamer.reload.referral_count.should == 0
      @stalker_gamer.reload.referral_count.should == 0
    end

    it 'is able to deactivate' do
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
          gamer1 = FactoryGirl.create(:gamer)
          gamer1.gamer_profile = GamerProfile.create(:facebook_id => @facebook_id, :gamer => gamer1)

          gamer2 = FactoryGirl.create(:gamer)
          gamer2.gamer_profile = GamerProfile.create(:facebook_id => @facebook_id, :gamer => gamer2)
        end
        it 'returns gamers based on facebook_id' do
          Gamer.find_all_gamer_based_on_channel(Invitation::FACEBOOK, @facebook_id).size.should == 2
        end
      end

      context 'when channel == Invitation::TWITTER' do
        before :each do
          @twitter_id = '2'
          FactoryGirl.create(:gamer, :twitter_id => @twitter_id)
          FactoryGirl.create(:gamer, :twitter_id => @twitter_id)
        end
        it 'returns gamers based on twitter_id' do
          Gamer.find_all_gamer_based_on_channel(Invitation::TWITTER, @twitter_id).size.should == 2
        end
      end
    end

    describe '#follow_gamer' do
      before :each do
        @gamer2 = FactoryGirl.create(:gamer)
        @gamer.follow_gamer(@gamer2)
      end

      it 'establishes friendship' do
        Friendship.find_by_id("#{@gamer.id}.#{@gamer2.id}").should_not be_nil
      end
    end

    describe '#invitation_for' do
      before :each do
        @gamer2 = FactoryGirl.create(:gamer, :twitter_id => '2')
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
          @invitation = FactoryGirl.create(:invitation, :gamer => @gamer, :channel => Invitation::TWITTER, :external_info => @gamer2.twitter_id)
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
        @gamer2 = FactoryGirl.create(:gamer)
        @gamer3 = FactoryGirl.create(:gamer)
        @gamer3.gamer_profile = GamerProfile.create(:gamer => @gamer3, :referred_by => @gamer.id)

        @invitation = FactoryGirl.create(:invitation, :gamer => @gamer, :channel => Invitation::TWITTER, :external_info => @authhash[:twitter_id], :status => Invitation::PENDING)
        @invitation2 = FactoryGirl.create(:invitation, :gamer => @gamer2, :channel => Invitation::TWITTER, :external_info => @authhash[:twitter_id], :status => Invitation::PENDING)
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
          Invitation.should_receive(:reconcile_pending_invitations).with(@gamer3, :external_info => @authhash[:twitter_id])
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
    it 'only deletes users deactivated 3 days ago' do
      5.times.each { FactoryGirl.create(:gamer) }
      5.times.each { FactoryGirl.create(:gamer, :deactivated_at => Time.zone.now) }
      5.times.each { FactoryGirl.create(:gamer, :deactivated_at => Time.zone.now - Gamer::DAYS_BEFORE_DELETION.days - 1.day) }
      Gamer.count.should == 15
      Gamer.to_delete.each(&:destroy)
      Gamer.count.should == 10
    end

    it 'also deletes friendships' do
      gamer = FactoryGirl.create(:gamer, :deactivated_at => Time.zone.now - Gamer::DAYS_BEFORE_DELETION.days - 1.day)

      stalker = FactoryGirl.create(:gamer)

      friendship = Friendship.new
      friendship.gamer_id  = stalker.id
      friendship.following_id = gamer.id
      friendship.save

      friend = FactoryGirl.create(:gamer)

      friendship = Friendship.new
      friendship.gamer_id  = gamer.id
      friendship.following_id = friend.id
      friendship.save

      friendship = Friendship.new
      friendship.gamer_id  = friend.id
      friendship.following_id = gamer.id
      friendship.save

      Friendship.count(:where => "gamer_id = '#{gamer.id}' or following_id = '#{gamer.id}'", :consistent => true).should == 3
      Gamer.to_delete.each(&:destroy)
      Friendship.count(:where => "gamer_id = '#{gamer.id}' or following_id = '#{gamer.id}'", :consistent => true).should == 0
    end

    it 'also deletes invitations' do
      gamer = FactoryGirl.create(:gamer, :deactivated_at => Time.zone.now - Gamer::DAYS_BEFORE_DELETION.days - 1.day)
      3.times do
        Invitation.create({
          :gamer_id => gamer.id,
          :channel => Invitation::EMAIL,
          :external_info => FactoryGirl.generate(:name),
        })
      end
      Invitation.count.should == 3
      Gamer.to_delete.each(&:destroy)
      Invitation.count.should == 0
    end

    it 'does not error out when deleted invitations are fulfilled' do

      gamer = FactoryGirl.create(:gamer, :deactivated_at => Time.zone.now - Gamer::DAYS_BEFORE_DELETION.days - 1.day)
      invitation = Invitation.create({
        :gamer_id => gamer.id,
        :channel => Invitation::EMAIL,
        :external_info => FactoryGirl.generate(:name),
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

  context ".serialized_extra_attributes_accessor" do
    before :each do
      @gamer = FactoryGirl.create(:gamer)
      Gamer::serialized_extra_attributes_accessor :completed_offer_count
    end

    it 'exposes the keys of the extra_attributes hash as gamer attributes' do
      @gamer.completed_offer_count = 10
      @gamer.save
      @gamer.completed_offer_count.should == @gamer.extra_attributes[:completed_offer_count]
    end
  end
end
