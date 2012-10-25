require 'spec_helper'

describe GetOffersHelper do
  describe '#offer_text' do
    before :each do
      @currency = FactoryGirl.create(:currency)
      @currency.update_attribute(:hide_rewarded_app_installs, false)
      @offer = FactoryGirl.create(:app).primary_offer
      @action_offer = FactoryGirl.create(:action_offer).primary_offer
    end

    it 'returns nil if not an app offer' do
      helper.featured_offer_text(@action_offer, @currency).should == ""
    end

    it 'returns download_and_run text if rewarded' do
      helper.featured_offer_text(@offer, @currency).should == helper.t('text.featured.download_and_run')
    end

    it 'returns try_out text if not rewarded' do
      @offer.rewarded = false
      helper.featured_offer_text(@offer, @currency).should == helper.t('text.featured.try_out')
    end
  end

  describe '#action_text' do
    before :each do
      @currency = FactoryGirl.create(:currency)
      @currency.update_attribute(:hide_rewarded_app_installs, false)
      @offer = FactoryGirl.create(:app).primary_offer
      @action_offer = FactoryGirl.create(:action_offer).primary_offer
    end

    it 'returns download text if App Offer' do
      helper.featured_offer_action_text(@offer).should == helper.t('text.featured.download')
    end

    it 'returns earn_now text if not App offer' do
      @offer.rewarded = false
      helper.featured_offer_action_text(@action_offer).should == helper.t('text.featured.earn_now')
    end
  end

  context "get links" do
    class TestClass
      include GetOffersHelper

      def initialize(more_data=1)
        @more_data_available = more_data
      end
    end

    before :each do
      @currency = FactoryGirl.create(:currency)
      @params = {'controller' => 'some_controller', 'action' => 'some_action',
                'currency_id' => 'some_currency', 'data' => 'some_data' }
      helper.stub(:params).and_return(@params)
      @test_instance = TestClass.new
      @test_instance.stub(:params).and_return(@params)
    end

    describe "#get_next_link_json" do
      before :each do
        url = @test_instance.get_next_link_json
        datastr = url.match(/data=([^"]+)/)[1]
        @data_params = ObjectEncryptor.decrypt(datastr)
      end

      it "should have currency_id in new data params", :links do
        @data_params['currency_id'].should == 'some_currency'
      end

      it "should have json in new data params", :links do
        @data_params['json'].should == '1'
      end

      it "should not have controller in new data params", :links do
        @data_params['controller'].should be_nil
      end

      it "should not have action in new data params", :links do
        @data_params['action'].should be_nil
      end

      it "should not have data in new data params", :links do
        @data_params['data'].should be_nil
      end
    end

    describe "#get_next_link_json_redesign" do
      before :each do
        url = @test_instance.get_next_link_json_redesign
        datastr = url.match(/data=([^"]+)/)[1]
        @data_params = ObjectEncryptor.decrypt(datastr)
      end

      it "should have currency_id in new data params", :links do
        @data_params['currency_id'].should == 'some_currency'
      end

      it "should have json in new data params", :links do
        @data_params['json'].should == '1'
      end

      it "should have redesign in new data params", :links do
        @data_params['json'].should == '1'
      end

      it "should not have controller in new data params", :links do
        @data_params['controller'].should be_nil
      end

      it "should not have action in new data params", :links do
        @data_params['action'].should be_nil
      end

      it "should not have data in new data params", :links do
        @data_params['data'].should be_nil
      end
    end

    describe "#get_currency_link" do
      before :each do
        url = helper.get_currency_link(@currency)
        datastr = url.match(/data=([^"]+)/)[1]
        @data_params = ObjectEncryptor.decrypt(datastr)
      end

      it "should have currency_id in new data params", :links do
        @data_params['currency_id'].should == @currency.id
      end

      it "should not have controller in new data params", :links do
        @data_params['controller'].should be_nil
      end

      it "should not have action in new data params", :links do
        @data_params['action'].should be_nil
      end

      it "should not have data in new data params", :links do
        @data_params['data'].should be_nil
      end
    end
  end
end
