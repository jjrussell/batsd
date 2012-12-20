require 'spec_helper'

describe CouponInstructionsController do
  describe '#new' do
  render_views
    before :each do
      @app = FactoryGirl.create(:app)
      App.stub(:find_in_cache).and_return(@app)
      @offer = @app.primary_offer
      @offer.reward_value = 10
      Offer.stub(:find_in_cache).and_return(@offer)
      @currency = FactoryGirl.create(:currency)
      @currency.stub(:active_and_future_sales).and_return({})
      Currency.stub(:find_in_cache).and_return(@currency)
      params = { :udid => '123', :publisher_app_id => @app.id,
                 :click_key => 'click', :currency_id => @currency.id,
                 :id => @offer.id, :offer_id => @offer.id,
                 :app_id => @app.id
               }
      @params = ObjectEncryptor.encrypt(params)
      @coupon = FactoryGirl.create(:coupon)
      Coupon.stub(:find_in_cache).and_return(@coupon)
      device = FactoryGirl.create(:device)
      Device.stub(:find).and_return(device)
      visit new_coupon_instruction_path(:data => @params)
    end
    context 'valid coupon' do
      it 'should successfully reach the page' do
        response.should be_success
      end
      it 'should have a text field email address in the view' do
        page.has_field?(:email_address)
      end
      it 'should have a submit button' do
        page.has_button?('Send Coupon')
      end
      it 'should have a coupon name' do
        page.has_content?(@coupon.name)
      end
      it 'should have currency name' do
        page.has_content?(@currency.name)
      end
      it 'should have publisher name' do
        page.has_content?(@app.name)
      end
      it 'should have coupon description' do
        page.has_content?(@coupon.description)
      end

      context 'valid email inputted' do
        before :each do
          Sqs.stub(:send_message).and_return(true)
          @offer.stub(:complete_action_url).and_return("#{API_URL}/coupons/complete?data=#{@params}")
          fill_in 'email_address', :with => 'tapjoy@tapjoy.com'
          click_button('Send Coupon')
        end

        it 'goes to complete action' do
          response.should render_template('coupons/complete')
        end
        it 'responds with 200' do
          response.should be_success
        end
        it 'has success on the page' do
          page.has_content?('Success')
        end
        it "has coupon's name" do
          page.has_content?(@coupon.name)
        end
        it 'should have a POST request to the create action' do
          response.should be_success
        end
        it "should have redirected to the coupons controller's complete action" do
          response.should render_template('coupons/complete')
        end
        it 'should have success on the page' do
          page.has_content?('Success')
        end
        it "should have coupon's name" do
          page.has_content?(@coupon.name)
        end
      end

      context 'blank email inputted' do
        before :each do
          click_button('Send Coupon')
        end
        it 'should redirect back to #new' do
          response.should render_template('coupon_instructions/new')
        end
        it 'should have a flash message' do
          page.has_content?('Input a valid email address.')
        end
        it 'should have a flash message' do
          page.has_button?('Send Coupon')
        end
        it 'should have a flash message' do
          page.has_field?(:email_address)
        end
      end

      context 'blank email inputted' do
        before :each do
          fill_in 'email_address', :with => 'tapjoy'
          click_button('Send Coupon')
        end
        it 'should redirect back to #new' do
          response.should render_template('coupon_instructions/new')
        end
        it 'should have a flash message' do
          page.has_content?('Input a valid email address.')
        end
      end
    end
  end

  describe '#create' do
    before :each do
      @app = FactoryGirl.create(:app)
      App.stub(:find_in_cache).and_return(@app)
      @offer = @app.primary_offer
      Offer.stub(:find_in_cache).and_return(@offer)
      @currency = FactoryGirl.create(:currency)
      @currency.stub(:active_and_future_sales).and_return(nil)
      Currency.stub(:find_in_cache).and_return(@currency)
      params = { :udid => '123', :publisher_app_id => @app.id,
                 :click_key => 'click', :currency_id => @currency.id,
                 :id => @offer.id, :offer_id => @offer.id,
                 :app_id => @app.id
               }
      @params = ObjectEncryptor.encrypt(params)
      @offer.stub(:complete_action_url).and_return("#{API_URL}/coupons/complete?data=#{@params}")
      @coupon = FactoryGirl.create(:coupon)
      Coupon.stub(:find_in_cache).and_return(@coupon)
      @device = FactoryGirl.create(:device)
      Device.stub(:find).and_return(@device)
      Sqs.stub(:send_message).and_return(true)
    end

    context 'valid post' do
      before :each do
        post(:create, :data => @params, :email_address => 'tapjoy@tapjoy.com')
      end
      it 'should redirect to coupons/complete action' do
        response.should redirect_to("#{API_URL}/coupons/complete?data=#{@params}")
      end
      it 'should respond with a 302' do
        should respond_with 302
      end
      it 'has coupon instance variable' do
        assigns(:coupon).should == @coupon
      end
      it 'sets device instance variable' do
        assigns(:device).should == @device
      end
      it 'sets offer instance variable' do
        assigns(:offer).should == @offer
      end
    end

    context 'blank email' do
      before :each do
        post(:create, :data => @params)
      end
      it 'redirects back to new' do
        should respond_with 400
      end
    end

    context 'invalid email' do
      before :each do
        post(:create, :data => @params, :email_address => 'tapjoy')
      end
      it 'redirects back to new' do
        response.should redirect_to(new_coupon_instruction_path(:data => @params))
      end
      it 'has a flash message' do
        flash[:notice].should == 'Input a valid email address.'
      end
    end

    context 'coupon has already been requested' do
      before :each do
        @device.set_pending_coupon(@offer.id)
        post(:create, :data => @params, :email_address => 'tapjoy@tapjoy.com')
      end
      it 'redirects back to games earn path' do
        response.should redirect_to(new_coupon_instruction_path(:data => @params))
      end
      it 'has a flash message' do
        flash[:notice].should == 'Coupon has already been requested.'
      end
    end
  end
end
