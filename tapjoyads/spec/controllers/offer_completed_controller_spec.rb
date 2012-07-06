require 'spec_helper'

describe OfferCompletedController do
  before :each do
    @click = mock()
    @click.stub(:id).and_return('test.another')
    @click.stub(:is_new).and_return(false)
    @click.stub(:udid).and_return('test')
    @click.stub(:advertiser_app_id).and_return('another')
    @click.stub(:installed_at).and_return(nil)
    @click.stub(:manually_resolved_at?).and_return(false)
    @device = mock()
    @device.stub(:set_last_run_time!)
    @offer = FactoryGirl.create(:app).primary_offer
    @offer.tapjoy_enabled = true
    @offer.payment = 1
    @offer.user_enabled = true
    @click.stub(:offer_id).and_return(@offer.id)
    @click.stub(:key).and_return(@click.id)
  end

  describe "#index" do
    context "with a generic offer" do
      before :each do
        Click.stub(:new).with(:key => @click.id).and_return(@click)
        Offer.stub(:find_in_cache).and_return(@offer)
        Device.stub(:new).with(:key => @click.udid).and_return(@device)
        @device.stub(:has_app?).with(@click.advertiser_app_id).and_return(false)
        @parameters = {:click_key => @click.id}
      end

      it "should give an error message on blank click_key" do
        get(:index, {})
        assigns(:error_message).should == "click_key required"
      end

      it "should resolve to the click" do
        get(:index, @parameters)
        response.should render_template('layouts/success')
      end

      context 'that requires servers to be whitelisted' do
        before :each do
          @offer.stub(:partner_use_server_whitelist?).and_return(true)
        end

        context 'when request does not match IP on whitelist' do
          it 'is rejected' do
            ServerWhitelist.stub(:ip_whitelist_includes?).and_return(false)
            get(:index, @parameters)
            response.should render_template('layouts/error')
            assigns(:error_message).should =~ /failed to convert/
          end

          context 'but the click was awarded by CS' do
            it 'succeeds' do
              @click.stub(:manually_resolved_at?).and_return(true)
              get(:index, @parameters)
              response.should render_template('layouts/success')
            end
          end
        end

        context 'when request matches IP on whitelist' do
          it 'succeeds' do
            ServerWhitelist.stub(:ip_whitelist_includes?).and_return(true)
            get(:index, @parameters)
            response.should render_template('layouts/success')
          end
        end
      end
    end
  end
end
