require 'spec_helper'

describe Games::Gamers::DevicesController do
  before :each do
    activate_authlogic
    fake_the_web
  end

  context 'when linking device' do
    before :each do
      user = Factory(:admin)
      partner = Factory(:partner, :users => [user])
      generic_offer_for_invite = Factory(:generic_offer, :partner => partner, :url => 'http://ws.tapjoyads.com/healthz?advertiser_app_id=TAPJOY_GENERIC_INVITE')

      @inviter = Factory(:gamer)
      @inviter.gamer_profile = GamerProfile.create(:gamer => @inviter, :referral_count => 0)
      click = Click.new(:key => "#{@inviter.id}.#{generic_offer_for_invite.id}")
      click.save

      invitation = Factory(:invitation, :gamer_id => @inviter.id)

      gamer = Factory(:gamer, :referrer => ObjectEncryptor.encrypt("#{invitation.id},#{generic_offer_for_invite.id}"))
      gamer.gamer_profile = GamerProfile.create(:gamer => gamer, :referred_by => @inviter.id)
      games_login_as(gamer)

      @data = {
        :udid              => Factory.next(:udid),
        :product           => Factory.next(:name),
        :version           => Factory.next(:name),
        :mac_address       => Factory.next(:name),
        :platform          => 'ios'
      }
    end

    it 'creates sub click key' do
      get(:finalize, {:data => ObjectEncryptor.encrypt(@data)})
      Click.new(:key => "#{@inviter.id}.invite[1]", :consistent => true).should_not be_new_record
    end

    it "queues the offer's click_tracking_urls properly" do
      offer = Factory(:app).primary_offer
      Click.any_instance.stubs(:offer).returns(offer)
      offer.expects(:queue_click_tracking_requests).once

      get(:finalize, {:data => ObjectEncryptor.encrypt(@data)})
    end
  end

end
