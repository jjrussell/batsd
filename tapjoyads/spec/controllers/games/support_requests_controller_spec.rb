require 'spec/spec_helper'

describe Games::SupportRequestsController do
  before :each do
    activate_authlogic
    fake_the_web

    @device = Factory(:device)

    @click1 = Factory(:click,           :udid => @device.key,
                                        :clicked_at => 1.hour.ago)
    @click2 = Factory(:click,           :udid => @device.key,
                                        :clicked_at => 1.hour.ago)
    @click1_dupe_old = Factory(:click,  :udid => @device.key,
                                        :currency_id => @click1.currency_id,
                                        :advertiser_app_id => @click1.advertiser_app_id,
                                        :publisher_app_id => @click1.publisher_app_id,
                                        :offer_id => @click1.offer_id,
                                        :clicked_at => 2.hours.ago)

    results = [ @click1, @click1_dupe_old, @click2 ]
    Click.stubs(:select_all).returns(results)
    GamesMailer.stubs(:deliver_contact_support)

    @gamer = Factory(:gamer)
    @gamer.gamer_profile = GamerProfile.create(:facebook_id => '0', :gamer => @gamer)
    @gamer.devices << GamerDevice.new(:device => @device)

    login_as(@gamer)
  end

  describe '#create' do
    context 'without supplying a message' do
      before :each do
        @params = { :type => 'contact_support' }
        @params['support_requests'] = { :content => "" }
      end

      it "re-renders #new if no message is provided" do
        post :create, @params
        response.should render_template("new")
      end
    end

    context 'with a message' do
      before :each do
        @params = { :type => 'contact_support' }
        @params['support_requests'] = { :content => "I'm needy and need help!" }
      end

      context 'with a click selected' do
        before :each do
          @params[:click_id] = @click1.id
          Click.stubs(:new).returns(@click1)
        end

        it 'associates the click with the support request' do
          mock_support_request = mock();
          mock_support_request.expects(:fill_from_click).with(is_a(Click), anything, anything, anything, anything)
          mock_support_request.expects(:save)
          SupportRequest.stubs(:new).returns(mock_support_request);

          post :create, @params
        end
      end

      context 'without a click selected' do
        it "doesn't associate a click with the support request" do
          mock_support_request = mock();
          mock_support_request.expects(:fill_from_click).with(nil, anything, anything, anything, anything)
          mock_support_request.expects(:save)
          SupportRequest.stubs(:new).returns(mock_support_request);

          post :create, @params
        end
      end

      it 'creates a SupportRequest' do
        post :create, @params
        SupportRequest.count(:where =>"gamer_id = '#{@gamer.id}'").should == 1
      end
    end
  end

  describe '#new' do
    before :each do
      @params = { :udid => @device.key }
    end

    context 'when format is set to JS' do
      before :each do
        @params[:format] = 'js'
      end

      context 'the @unresolved_clicks collection' do
        it 'includes both "correct" clicks' do
          get :new, @params
          assigns(:unresolved_clicks).should include @click1
          assigns(:unresolved_clicks).should include @click2
        end

        it "doesn't include the older duplicate click" do
          get :new, @params
          assigns(:unresolved_clicks).should_not include @click1_dupe_old
        end

        it "limits the number of clicks in the list to 20" do
          results = [ @click1, @click1_dupe_old, @click2 ]
          20.times { |i| results << Factory(:click, :udid => @device.key, :clicked_at => 1.hour.ago) }
          Click.stubs(:select_all).returns(results) # results.size is 23

          get :new, @params
          assigns(:unresolved_clicks).size.should == 20
        end
      end
    end

    context 'when format is not set to JS' do
      it 'finds the current gamer' do
        get :new, @params
        assigns(:current_gamer).should == @gamer
      end
    end
  end
end
