require 'spec_helper'

describe OfferAgeGatingController do

  describe '#redirect_to_click' do
    it 'should redirect to the correct click url' do

      now = Time.zone.now
      Timecop.freeze(now)

      udid = '0000222200002229'
      offer = FactoryGirl.create(:generic_offer).primary_offer
      currency = FactoryGirl.create(:currency)
      app = FactoryGirl.create(:app)
      publisher_user_id = 'testuser'
      source = "offerwall"

      params={ :udid => udid,
               :offer_id => offer.id,
               :app_id => app.id,
               :currency_id => currency.id,
               :display_multiplier => 1,
               :source => source,
               :publisher_user_id => publisher_user_id,
               :options => {}
      }
      data={ :data => ObjectEncryptor.encrypt(params) }
      get(:redirect_to_click, data)
      response.should be_redirect

      url_params = { :publisher_app => app,
                     :publisher_user_id => publisher_user_id,
                     :udid => udid,
                     :currency_id => currency.id,
                     :source => source,
                     :viewed_at => now
      }
      response.should redirect_to(offer.click_url(url_params))

      Timecop.return
    end

  end

  describe '#redirect_to_get_offers' do
    it 'should cache offer.age_gating.device.offer' do
      udid = '0000222200002229'
      offer = FactoryGirl.create(:generic_offer).primary_offer

      params={ :udid => udid,
               :offer_id => offer.id
      }
      data={ :data => ObjectEncryptor.encrypt(params) }

      Mc.should_receive(:distributed_put).once.with("#{Offer::MC_KEY_AGE_GATING_PREFIX}.#{udid}.#{offer.id}", "gating", false, 2.hour)

      get(:redirect_to_get_offers, data)
    end
  end



end
