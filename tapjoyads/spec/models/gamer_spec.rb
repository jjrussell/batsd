require 'spec_helper'

describe Gamer do
  context 'when associating' do
    it { should have_many :gamer_devices }
    it { should have_many :invitations }
    it { should have_one :gamer_profile }
  end

  context 'when validating' do
    it { should validate_presence_of :email }
  end

  context 'when delegating' do
    it "delegates facebook_id, facebook_id?, fb_access_token, referred_by, referred_by=, referred_by?, referral_count to gamer_profile" do
      delegated_methods = [ :facebook_id, :facebook_id?, :fb_access_token, :referred_by, :referred_by=, :referred_by?, :referral_count ]
     	delegated_methods.each do |dm|
     	  subject.should respond_to dm
     	end
    end
  end

  before :each do
    fake_the_web
    @gamer = Factory(:gamer, :twitter_id => '1')
    @gamer.gamer_profile = GamerProfile.create(:facebook_id => '0', :gamer => @gamer)
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
