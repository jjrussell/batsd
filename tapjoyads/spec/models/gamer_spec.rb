require 'spec_helper'

describe Gamer do
  before :each do
    fake_the_web
  end

  subject { Factory(:user) }

  context "Gamer" do
    before :each do
      @gamer = Factory(:gamer)
      @gamer.gamer_profile = GamerProfile.create(:gamer => @gamer)
    end

    it 'is compatible with old invitation' do
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

    it 'sets up friendships' do
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

    it 'is able to deactivate' do
      @gamer.deactivate!
      @gamer.deactivated_at.should > Time.zone.now - 1.minute
      @gamer.deactivated_at.should < Time.zone.now
    end

  end

  context "Deleting Gamers" do
    it 'only deletes users deactivated 3 days ago' do
      5.times.each { Factory(:gamer) }
      5.times.each { Factory(:gamer, :deactivated_at => Time.zone.now) }
      5.times.each { Factory(:gamer, :deactivated_at => Time.zone.now - Gamer::DAYS_BEFORE_DELETION.days - 1.day) }
      Gamer.count.should == 15
      Gamer.to_delete.each(&:destroy)
      Gamer.count.should == 10
    end

    it 'also deletes friendships' do
      gamer = Factory(:gamer, :deactivated_at => Time.zone.now - Gamer::DAYS_BEFORE_DELETION.days - 1.day)

      stalker = Factory(:gamer)

      friendship = Friendship.new
      friendship.gamer_id  = stalker.id
      friendship.following_id = gamer.id
      friendship.save

      friend = Factory(:gamer)

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

    it 'does not error out when deleted invitations are fulfilled' do

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
