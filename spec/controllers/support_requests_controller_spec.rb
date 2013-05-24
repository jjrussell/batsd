require 'spec_helper'

describe SupportRequestsController do
  before :each do
    @app = FactoryGirl.create(:app)
    @currency = FactoryGirl.create(:currency)
    @udid = 'test udid'
  end

  describe '#incomplete_offers' do
    it 'should perform the proper SimpleDB query' do
      now = Time.zone.now
      Timecop.freeze(now) do
        conditions = ["udid = ? and currency_id = ? and clicked_at > ? and manually_resolved_at is null", @udid, @currency.id, 30.days.ago.to_f]

        Click.should_receive(:select_all).with({ :conditions => conditions }).once.and_return([])
        get(:incomplete_offers, :app_id => @app.id, :currency_id => @currency.id, :udid => @udid)
      end
    end
  end

  describe '#create' do
    context 'duplicate support request' do
      before :each do
        @app = FactoryGirl.create(:app)
        App.stub(:find_in_cache).and_return(@app)
        @offer = @app.primary_offer
        Offer.stub(:find_in_cache).and_return(@offer)
        @currency = FactoryGirl.create(:currency)
        Currency.stub(:find_in_cache).and_return(@currency)
        @support_request = FactoryGirl.create(:support_request, :offer_id => @offer.id)
        @params = { :description => 'description',
                    :offer_id => @support_request.offer_id,
                    :udid => @support_request.udid,
                    :currency_id => @currency.id,
                    :app_id => @app.id,
                    :email_address => 'test@test.com'
        }
        @controller.should_receive(:duplicate_support_request?).and_return(true)
        post(:create, @params)
      end

      it 'should render new template' do
        response.should render_template('new')
      end
      it 'should render a duplicate support request error message' do
        flash.now[:error].should == "You've already submitted a support request for this offer."
      end
    end
    context 'valid support request' do
      before :each do
        @app = FactoryGirl.create(:app)
        App.stub(:find_in_cache).and_return(@app)
        @offer = @app.primary_offer
        Offer.stub(:find_in_cache).and_return(@offer)
        @currency = FactoryGirl.create(:currency)
        Currency.stub(:find_in_cache).and_return(@currency)
        @device = FactoryGirl.create(:device)
        @click = FactoryGirl.create(:click)
        @support_request = FactoryGirl.build(:support_request, :offer_id => @offer.id, :click_id => @click.id)
        @params = { :description => 'description',
                    :offer_id => @offer.id,
                    :udid => 'test_udid',
                    :currency_id => @currency.id,
                    :app_id => @app.id,
                    :email_address => 'test@test.com'
        }
        mailer = double('TapjoyMailer')
        mailer.should_receive(:deliver)
        TapjoyMailer.should_receive(:support_request).and_return(mailer)
        SupportRequest.should_receive(:new).and_return(@support_request)
        SupportRequest.stub(:fill_from_params)
        SupportRequest.stub(:save).and_return(true)
        Click.should_receive(:new).with(:key => @support_request.click_id).and_return(@click)
        Device.should_receive(:new).with(:key => @params[:udid]).and_return(@device)
        @controller.should_receive(:duplicate_support_request?).and_return(false)
        post(:create, @params)
      end
      it 'should respond with 200' do
        should respond_with 200
      end
      it 'should render support request view' do
        response.should render_template('support_request')
      end
      it 'has currency instance variable' do
        assigns(:currency).should == @currency
      end
      it 'has app instance variable' do
        assigns(:app).should == @app
      end
      it 'has offer instance variable' do
        assigns(:offer).should == @offer
      end
    end
  end
end
