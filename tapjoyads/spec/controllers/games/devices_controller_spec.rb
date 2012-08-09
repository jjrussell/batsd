require 'spec_helper'

describe Games::DevicesController do
  before :each do
    activate_authlogic
  end

  context 'when linking device' do
    before :each do
      user = FactoryGirl.create(:admin_user)
      partner = FactoryGirl.create(:partner, :users => [user])
      generic_offer_for_invite = FactoryGirl.create(:generic_offer, :partner => partner, :url => 'http://ws.tapjoyads.com/healthz?advertiser_app_id=TAPJOY_GENERIC_INVITE')

      @inviter = FactoryGirl.create(:gamer)
      @inviter.gamer_profile = GamerProfile.create(:gamer => @inviter, :referral_count => 0)
      click = Click.new(:key => "#{@inviter.id}.#{generic_offer_for_invite.id}")
      click.save

      invitation = FactoryGirl.create(:invitation, :gamer_id => @inviter.id)

      @gamer = FactoryGirl.create(:gamer, :referrer => ObjectEncryptor.encrypt("#{invitation.id},#{generic_offer_for_invite.id}"))
      @gamer.gamer_profile = GamerProfile.create(:gamer => @gamer, :referred_by => @inviter.id)
      games_login_as(@gamer)

      @device = Device.new(:key => FactoryGirl.generate(:udid))
      Device.stub(:new).and_return(@device)

      @data = {
        :udid              => @device.key,
        :product           => FactoryGirl.generate(:name),
        :version           => FactoryGirl.generate(:name),
        :mac_address       => FactoryGirl.generate(:name),
        :platform          => 'ios'
      }
    end

    context 'if gamer\'s referrer is Tapjoy Registration offer' do
      it 'does not add Tapjoy Registration offer to device\'s "installed apps"' do
        @gamer.update_attributes!(:referrer => "tjreferrer:#{@device.tjgames_registration_click_key}")

        get(:finalize, {:data => ObjectEncryptor.encrypt(@data)})
        @device.has_app?(TAPJOY_GAMES_REGISTRATION_OFFER_ID).should_not be_true
      end
    end

    context 'if gamer\'s referrer is not Tapjoy Registration offer' do
      it 'adds Tapjoy Registration offer to device\'s "installed apps"' do
        get(:finalize, {:data => ObjectEncryptor.encrypt(@data)})
        @device.has_app?(TAPJOY_GAMES_REGISTRATION_OFFER_ID).should be_true
      end
    end

    it 'creates sub click key' do
      get(:finalize, {:data => ObjectEncryptor.encrypt(@data)})
      Click.new(:key => "#{@inviter.id}.invite[1]", :consistent => true).should_not be_new_record
    end
  end

end
