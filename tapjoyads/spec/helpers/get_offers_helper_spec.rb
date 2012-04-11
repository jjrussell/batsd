require 'spec_helper'

describe GetOffersHelper do
  describe '#offer_text' do
    before :each do
      @currency = Factory(:currency)
      @currency.update_attribute(:hide_rewarded_app_installs, false)
      @offer = Factory(:app).primary_offer
      @action_offer = Factory(:action_offer).primary_offer
    end

    it 'returns nill if not an app offer' do
      helper.offer_text(@action_offer, @currency).should == nil
    end

    it 'returns download_and_run text if rewarded' do
      helper.offer_text(@offer, @currency).should == helper.t('text.featured.download_and_run')
    end

    it 'returns try_out text if not rewarded' do
      @offer.rewarded = false
      helper.offer_text(@offer, @currency).should == helper.t('text.featured.try_out')
    end
  end

  describe '#action_text' do
    before :each do
      @currency = Factory(:currency)
      @currency.update_attribute(:hide_rewarded_app_installs, false)
      @offer = Factory(:app).primary_offer
      @action_offer = Factory(:action_offer).primary_offer
    end

    it 'returns download text if App Offer' do
      helper.action_text(@offer).should == helper.t('text.featured.download')
    end

    it 'returns earn_now text if not App offer' do
      @offer.rewarded = false
      helper.action_text(@action_offer).should == helper.t('text.featured.earn_now')
    end
  end
end
