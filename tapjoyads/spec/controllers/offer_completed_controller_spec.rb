require 'spec/spec_helper'

describe OfferCompletedController do
  before :each do
    @click = mock()
    @click.stubs(:id).returns('test.another')
    @click.stubs(:is_new).returns(false)
    @click.stubs(:udid).returns('test')
    @click.stubs(:advertiser_app_id).returns('another')
    @click.stubs(:installed_at).returns(nil)
    @device = mock()
    @device.stubs(:set_last_run_time!)
    @offer = Factory(:app).primary_offer
    @offer.tapjoy_enabled = true
    @offer.payment = 1
    @offer.user_enabled = true
    @click.stubs(:offer_id).returns(@offer.id)
    @click.stubs(:key).returns(@click.id)
  end

  describe "#index" do
    context "with a generic offer" do
      before :each do
      end

      it "should give an error message on blank click_key" do
        get(:index, {})
        assigns(:error_message).should == "click_key required"
      end

      it "should resolve to the click" do
        Click.stubs(:new).with(:key => @click.id).returns(@click)
        Offer.stubs(:find_in_cache).returns(@offer)
        Device.stubs(:new).with(:key => @click.udid).returns(@device)
        @device.stubs(:has_app?).with(@click.advertiser_app_id).returns(false)
        parameters = {:click_key => @click.id}
        get(:index, parameters)
        response.should render_template('layouts/success')
      end

    end
  end
end
