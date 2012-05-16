require 'spec_helper'

describe Dashboard::OffersController do
  before :each do
    activate_authlogic
  end

  before :each do
    @user = Factory :admin
    @partner = Factory(:partner, :users => [@user])
    @app = Factory(:app, :partner => @partner)
    login_as @user
  end

  it 'does not have any offers initially' do
    @app.primary_non_rewarded_featured_offer.should be_nil
    @app.primary_rewarded_featured_offer.should be_nil
    @app.primary_non_rewarded_offer.should be_nil
  end

  context 'a non-rewarded featured offer' do
    before :each do
      post(:create, :app_id => @app.id, :offer_type => 'non_rewarded_featured')
    end

    it 'is created' do
      offer = @app.primary_non_rewarded_featured_offer
      offer.should be_a Offer
      offer.should_not be_rewarded
      offer.should be_featured
      response.should redirect_to(:action => :edit, :id => offer.id)
    end

    it 'does not show up as a rewarded featured offer' do
      @app.primary_rewarded_featured_offer.should be_nil
    end

    it 'does not show up as a non-rewarded offer' do
      @app.primary_non_rewarded_offer.should be_nil
    end
  end

  context 'with a rewarded featured offer' do
    before :each do
      post(:create, :app_id => @app.id, :offer_type => 'rewarded_featured')
    end

    it 'is created' do
      offer = @app.primary_rewarded_featured_offer
      offer.should be_a Offer
      offer.should be_rewarded
      offer.should be_featured
      response.should redirect_to(:action => :edit, :id => offer.id)
    end

    it 'does not show up as a non-rewarded featured offer' do
      @app.primary_non_rewarded_featured_offer.should be_nil
    end

    it 'does not show up as a non-rewarded offer' do
      @app.primary_non_rewarded_offer.should be_nil
    end
  end

  context 'a non-rewarded offer' do
    before :each do
      post(:create, :app_id => @app.id, :offer_type => 'non_rewarded')
    end

    it 'is created' do
      offer = @app.primary_non_rewarded_offer
      offer.should be_a Offer
      offer.should_not be_rewarded
      offer.should_not be_featured
      response.should redirect_to(:action => :edit, :id => offer.id)
    end

    it 'does not show up as a featured offer' do
      @app.primary_non_rewarded_featured_offer.should be_nil
      @app.primary_rewarded_featured_offer.should be_nil
    end
  end

  describe '#new' do
    context "when 'rewarded_featured'" do
      it 'is rewarded and featured' do
        Offer.stubs(:new).with( { :featured => true, :rewarded => true } ).once
        get(:new, :app_id => @app.id, :offer_type => 'rewarded_featured')
      end
    end

    context "when 'non_rewarded_featured'" do
      it 'is not rewarded, but featured' do
        Offer.stubs(:new).with( { :featured => true, :rewarded => false } ).once
        get(:new, :app_id => @app.id, :offer_type => 'non_rewarded_featured')
      end
    end

    context "when 'non_rewarded'" do
      it 'is not rewarded and not featured' do
        Offer.stubs(:new).with( { :featured => false, :rewarded => false } ).once
        get(:new, :app_id => @app.id, :offer_type => 'non_rewarded')
      end
    end

    context 'when offer type not specified' do
      it 'is rewarded, but not featured' do
        Offer.stubs(:new).with( { :featured => false, :rewarded => true } ).once
        get(:new, :app_id => @app.id)
      end
    end
  end

  describe '#edit' do
    context 'when app offer is enabled' do
      before :each do
        @offer = mock('mock offer', :tapjoy_enabled? => true)
        @controller.stubs(:find_app).with(@app.id).returns(@app)
        @controller.stubs(:log_activity).with(@offer)
        mock_find = mock('test')
        mock_find.stubs(:find).with('oid').returns(@offer)
        @app.stubs(:offers).returns(mock_find)
      end

      it 'will proceed to the view' do
        @offer.expects(:rewarded?).never
        get(:edit, :app_id => @app.id, :id => 'oid')
      end
    end

    context 'when app offer is disabled' do
      before :each do
        @offer = mock('mock offer', :tapjoy_enabled? => false)
        @controller.stubs(:find_app).with(@app.id).returns(@app)
        @controller.stubs(:log_activity).with(@offer)
        mock_find = mock('test')
        mock_find.stubs(:find).with('oid').returns(@offer)
        @app.stubs(:offers).returns(mock_find)
      end

      context 'when offer is rewarded and not featured' do
        before :each do
          @offer.stubs(:rewarded?).returns(true)
          @offer.stubs(:featured?).returns(false)
          mock_pending_list = mock('pending_list')
          mock_pending_list.stubs(:pending).returns([mock('some_junk')])
          @offer.stubs(:enable_offer_requests).returns(mock_pending_list)
          @controller.instance_eval{flash.stubs(:sweep)}
        end

        context 'when offer is integrated' do
          it 'flashes a notice' do
            @offer.stubs(:integrated?).returns(true)
            get(:edit, :app_id => @app.id, :id => 'oid')
            flash.now[:notice].should be_present
          end
        end

        context 'when offer is not integrated' do
          it 'flashes a warning' do
            @offer.stubs(:integrated?).returns(false)
            @offer.stubs(:item).returns(mock('item', :sdk_url => 'some_junk'))

            get(:edit, :app_id => @app.id, :id => 'oid')
            flash.now[:warning].should be_present
          end
        end
      end

      context 'when offer is not rewarded' do
        before :each do
          @offer.stubs(:rewarded?).returns(false)
          @controller.instance_eval{flash.stubs(:sweep)}
        end

        context 'when no enable offer requests pending' do
          before :each do
            @mock_pending_list = mock('pending_list', :pending => nil)
            @offer.stubs(:enable_offer_requests).returns(@mock_pending_list)
          end
          it 'will build a new enable offer request' do
            @mock_pending_list.stubs(:build).once
            get(:edit, :app_id => @app.id, :id => 'oid')
          end
        end
      end
    end
  end

  describe '#toggle' do
    before :each do
        @offer = mock('mock offer', :user_enabled= => true)
        mock_offers = mock('get_offer')
        mock_offers.stubs(:find).with(@offer.object_id.to_s).returns(@offer)
        @controller.stubs(:set_recent_partners)
        @controller.stubs(:current_partner).returns(mock('offers', :offers => mock_offers))
        @controller.stubs(:log_activity).with(@offer)
      end

    context 'when user_enabled is saved properly' do
      it 'will render nothing' do
        @offer.stubs(:save).returns(true)
        post(:toggle, :id => @offer.object_id.to_s, :user_enabled => true)
        response.body.should_not be_present
      end
    end

    context 'when user_enabled is not saved properly' do
      it 'will render json error' do
        @offer.stubs(:save).returns(false)
        post(:toggle, :id => @offer.object_id.to_s, :user_enables => true)
        response.body.should == {:error => true}.to_json
      end
    end
  end

  describe '#percentile' do
    context 'when model method throws in error' do
      it 'returns N/A for values' do
        get(:percentile, :app_id => @app.id, :bid => '0.24')
        response.body.should == {:percentile => "N/A", :ordinalized_percentile => "N/A" }.to_json
      end
    end

    context 'when percentile is returned properly' do
      it 'returns percentile and ordinalized percentiles in a json response' do
        offer = mock('offer', :percentile => 24)
        offer.stubs(:bid=)
        @controller.stubs(:find_app).with(@app.id).returns(@app)
        @controller.stubs(:log_activity).with(offer)
        @app.stubs(:primary_offer).returns(offer)

        get(:percentile, :app_id => @app.id, :bid => '24')
        response.body.should == {:percentile => 24, :ordinalized_percentile => 24.ordinalize }.to_json
      end
    end
  end

  describe '#update' do
    context 'when not permitted to edit->statz' do
      before :each do
        @controller.stubs(:permitted_to?).with(:edit, :dashboard_statz).returns(false)
        @safe_attributes = [:daily_budget, :user_enabled, :bid, :self_promote_only, :min_os_version, :screen_layout_sizes, :countries]

        @controller.stubs(:find_app).with(@app.id).returns(@app)
        @offer = mock('offer')
        @controller.stubs(:log_activity).with(@offer)
        @app.stubs(:primary_offer).returns(@offer)
      end

      it 'will call with base attributes' do
        @offer.stubs(:safe_update_attributes).with({}, @safe_attributes).once.returns(true)
        post(:update, :app_id => @app.id.to_s, :offer => {})
      end

      context 'when it updates properly' do
        it 'flashes a success notice' do
          @controller.instance_eval{flash.stubs(:sweep)}
          @offer.stubs(:safe_update_attributes).with({}, @safe_attributes).returns(true)
          post(:update, :app_id => @app.id, :offer => {})
          flash[:notice].should == 'Your offer was successfully updated.'
        end
      end

      context 'when the update fails' do
        context 'when offer has pending enable_offer_requests' do
          before :each do
            @controller.instance_eval{flash.now.stubs(:sweep)}
            @offer.stubs(:safe_update_attributes).with({}, @safe_attributes).returns(false)
            mock_enable_requests = mock('enable_requests')
            mock_enable_requests.stubs(:pending).returns(['test'])
            @controller.instance_eval{flash.stubs(:sweep)}
            @offer.stubs(:enable_offer_requests).returns(mock_enable_requests)
          end

          it 'assigns the first pending enable offer' do
            post(:update, :app_id => @app.id, :offer => {})
            assigns(:enable_request).should == 'test'
          end

          it 'flashes an error' do
            post(:update, :app_id => @app.id, :offer => {})
            flash[:error].should == 'Your offer could not be updated.'
          end
        end

        context 'when offer does not have pending enable_offer_requests' do
          before :each do
            @controller.instance_eval{flash.now.stubs(:sweep)}
            @offer.stubs(:safe_update_attributes).with({}, @safe_attributes).returns(false)
            mock_enable_requests = mock('enable_requests')
            mock_enable_requests.stubs(:pending).returns(nil)
            mock_enable_requests.stubs(:build).returns('test')
            @controller.instance_eval{flash.stubs(:sweep)}
            @offer.stubs(:enable_offer_requests).returns(mock_enable_requests)
          end

          it 'assigns the built enable offer' do
            post(:update, :app_id => @app.id, :offer => {})
            assigns(:enable_request).should == 'test'
          end

          it 'flashes an error' do
            post(:update, :app_id => @app.id, :offer => {})
            flash[:error].should == 'Your offer could not be updated.'
          end
        end
      end
    end

    context 'when permitted to edit->statz' do
      before :each do
        @controller.stubs(:permitted_to?).with(:edit, :dashboard_statz).returns(true)
        @safe_attributes = [ :daily_budget, :user_enabled, :bid, :self_promote_only, :min_os_version, :screen_layout_sizes, :countries, :tapjoy_enabled, :allow_negative_balance, :pay_per_click, :name, :name_suffix, :show_rate, :min_conversion_rate, :device_types, :publisher_app_whitelist, :overall_budget, :min_bid_override, :dma_codes, :regions, :carriers, :cities ]
        @controller.stubs(:find_app).with(@app.id).returns(@app)
        @offer = mock('offer')
        @controller.stubs(:log_activity).with(@offer)
        @app.stubs(:primary_offer).returns(@offer)
      end

      it 'will call with expanded attributes' do
        @offer.stubs(:safe_update_attributes).with({}, @safe_attributes).once.returns(true)
        post(:update, :app_id => @app.id.to_s, :offer => {})
      end
    end
  end
end
