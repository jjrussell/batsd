require 'spec/spec_helper'

describe OfferCompletedController do
  before :each do
    @click = mock()
    @click.stub(:id).and_return('test.another')
    @click.stub(:is_new).and_return(false)
    @click.stub(:udid).and_return('test')
    @click.stub(:advertiser_app_id).and_return('another')
    @click.stub(:installed_at).and_return(nil)
    @device = mock()
    @device.stub(:set_last_run_time!)
    @offer = Factory(:app).primary_offer
    @offer.tapjoy_enabled = true
    @offer.payment = 1
    @offer.user_enabled = true
    @click.stub(:offer_id).and_return(@offer.id)
    @click.stub(:key).and_return(@click.id)
  end

  describe "#index" do
    context "with a generic offer" do
      it "should give an error message on blank click_key" do
        get(:index, {})
        assigns(:error_message).should == "click_key required"
      end

      it "should resolve to the click" do
        Click.stub(:new).with(:key => @click.id).and_return(@click)
        Offer.stub(:find_in_cache).and_return(@offer)
        Device.stub(:new).with(:key => @click.udid).and_return(@device)
        @device.stub(:has_app?).with(@click.advertiser_app_id).and_return(false)
        parameters = {:click_key => @click.id}
        get(:index, parameters)
        response.should render_template('layouts/success')
      end

    end
  end
end
