require 'spec/spec_helper'

describe OfferCompletedController do
  before :each do
    @click = mock()
    @click.stubs(:id).returns( 'test.another')
    @click.stubs(:is_new).returns( false)
    @click.stubs(:udid).returns(  'test')
    @click.stubs(:advertiser_app_id).returns( 'another' )
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

      it "should resolve to the new tracked click" do
        generic_offer_click = GenericOfferClick.new
        generic_offer_click.click_id = @click.id
        GenericOfferClick.stubs(:find).with(generic_offer_click.id).returns(generic_offer_click)
        Click.stubs(:new).with(:key => @click.id).returns(@click)
        Offer.stubs(:find_in_cache).returns(@offer)
        Device.stubs(:new).with(:key => @click.udid).returns(@device)
        @device.stubs(:has_app?).with(@click.advertiser_app_id).returns(false)
        parameters = {:click_key => generic_offer_click.id}
        get(:index, parameters)
        response.should render_template('layouts/success')
      end

      it "should default to the random guid if not tracked" do
        @click.stubs(:id).returns( '123456')
        GenericOfferClick.stubs(:find).with(@click.id).returns(nil)
        Click.stubs(:new).with(:key => @click.id).returns(@click)
        Offer.stubs(:find_in_cache).returns(@offer)
        Device.stubs(:new).with(:key => @click.udid).returns(@device)
        @device.stubs(:has_app?).with(@click.advertiser_app_id).returns(false)
        parameters = {:click_key => @click.id}
        get(:index, parameters)
        response.should render_template('layouts/success')
      end

      it "should never attempt conversion when a normal click" do
        GenericOfferClick.expects(:find).never
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
