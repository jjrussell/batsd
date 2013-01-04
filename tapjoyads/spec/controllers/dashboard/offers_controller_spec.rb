require 'spec_helper'

describe Dashboard::OffersController do
  before :each do
    activate_authlogic
  end

  before :each do
    @user = FactoryGirl.create :admin
    @partner = FactoryGirl.create(:partner, :users => [@user])
    @app = FactoryGirl.create(:app, :partner => @partner)
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
        Offer.stub(:new).with( { :featured => true, :rewarded => true } ).once
        get(:new, :app_id => @app.id, :offer_type => 'rewarded_featured')
      end
    end

    context "when 'non_rewarded_featured'" do
      it 'is not rewarded, but featured' do
        Offer.stub(:new).with( { :featured => true, :rewarded => false } ).once
        get(:new, :app_id => @app.id, :offer_type => 'non_rewarded_featured')
      end
    end

    context "when 'non_rewarded'" do
      it 'is not rewarded and not featured' do
        Offer.stub(:new).with( { :featured => false, :rewarded => false } ).once
        get(:new, :app_id => @app.id, :offer_type => 'non_rewarded')
      end
    end

    context 'when offer type not specified' do
      it 'is rewarded, but not featured' do
        Offer.stub(:new).with( { :featured => false, :rewarded => true } ).once
        get(:new, :app_id => @app.id)
      end
    end
  end

  describe '#edit' do
    context 'offer id is given in place of app id' do
      it 'gracefully redirects' do
        offer = FactoryGirl.create :action_offer, :app => @app
        get(:edit, :app_id => offer.id, :id => offer.id)
        response.should redirect_to(:controller => 'dashboard/apps', :action => :show, :id => @app.id)
      end
    end

    context 'when app offer is enabled' do
      before :each do
        @offer = mock('mock offer', :tapjoy_enabled? => true)
        @offer.should_receive(:app_metadata).and_return(@app.primary_app_metadata)
        @controller.stub(:find_app).with(@app.id, {:redirect_on_nil => false}).and_return(@app)
        @controller.stub(:log_activity).with(@offer)
        mock_find = mock('test')
        mock_find.stub(:find).with('oid').and_return(@offer)
        @app.stub(:offers).and_return(mock_find)
      end

      it 'will proceed to the view' do
        @offer.should_receive(:rewarded?).never
        get(:edit, :app_id => @app.id, :id => 'oid')
      end
    end

    context 'when app offer is disabled' do
      before :each do
        @offer = mock('mock offer', :tapjoy_enabled? => false)
        @offer.should_receive(:app_metadata).and_return(@app.primary_app_metadata)
        @controller.stub(:find_app).with(@app.id, {:redirect_on_nil => false}).and_return(@app)
        @controller.stub(:log_activity).with(@offer)
        mock_find = mock('test')
        mock_find.stub(:find).with('oid').and_return(@offer)
        @app.stub(:offers).and_return(mock_find)
      end

      context 'when offer is rewarded and not featured' do
        before :each do
          @offer.stub(:rewarded?).and_return(true)
          @offer.stub(:featured?).and_return(false)
          mock_pending_list = mock('pending_list')
          mock_pending_list.stub(:pending).and_return([mock('some_junk')])
          @offer.stub(:enable_offer_requests).and_return(mock_pending_list)
          @controller.instance_eval{flash.stub(:sweep)}
        end

        context 'when offer is integrated' do
          it 'flashes a notice' do
            @offer.stub(:integrated?).and_return(true)
            get(:edit, :app_id => @app.id, :id => 'oid')
            flash.now[:notice].should be_present
          end
        end

        context 'when offer is not integrated' do
          it 'flashes a warning' do
            @offer.stub(:integrated?).and_return(false)
            @offer.stub(:item).and_return(mock('item', :sdk_url => 'some_junk'))

            get(:edit, :app_id => @app.id, :id => 'oid')
            flash.now[:warning].should be_present
          end
        end
      end

      context 'when offer is not rewarded' do
        before :each do
          @offer.stub(:rewarded?).and_return(false)
          @controller.instance_eval{flash.stub(:sweep)}
        end

        context 'when no enable offer requests pending' do
          before :each do
            @mock_pending_list = mock('pending_list', :pending => nil)
            @offer.stub(:enable_offer_requests).and_return(@mock_pending_list)
          end
          it 'will build a new enable offer request' do
            @mock_pending_list.stub(:build).once
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
        mock_offers.stub(:find).with(@offer.object_id).and_return(@offer)
        @controller.stub(:set_recent_partners)
        @controller.stub(:current_partner).and_return(mock('offers', :offers => mock_offers))
        @controller.stub(:log_activity).with(@offer)
      end

    context 'when user_enabled is saved properly' do
      it 'will render nothing' do
        @offer.stub(:save).and_return(true)
        post(:toggle, :id => @offer.object_id, :user_enabled => true)
        response.body.should_not be_present
      end
    end

    context 'when user_enabled is not saved properly' do
      it 'will render json error' do
        @offer.stub(:save).and_return(false)
        post(:toggle, :id => @offer.object_id, :user_enables => true)
        response.should be_error
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
        offer.stub(:bid=)
        @controller.stub(:find_app).with(@app.id, {:redirect_on_nil => false}).and_return(@app)
        @controller.stub(:log_activity).with(offer)
        @app.stub(:primary_offer).and_return(offer)

        get(:percentile, :app_id => @app.id, :bid => '24')
        response.body.should == {:percentile => 24, :ordinalized_percentile => 24.ordinalize }.to_json
      end
    end
  end

  describe '#update' do
    context 'when not permitted to edit->dashboard_statz' do
      before :each do
        @controller.stub(:permitted_to?).with(:edit, :dashboard_statz).and_return(false)
        @safe_attributes = [:daily_budget, :user_enabled, :bid, :self_promote_only,
          :min_os_version, :screen_layout_sizes, :countries, :prerequisite_offer_id,
          :exclusion_prerequisite_offer_ids, :daily_cap_type,
          :featured_ad_action, :featured_ad_content, :featured_ad_color]

        @controller.stub(:find_app).with(@app.id, {:redirect_on_nil => false}).and_return(@app)
        @offer = @app.primary_offer
        @controller.stub(:log_activity).with(@offer)
        @app.stub_chain(:offers, :find).and_return(@offer)
        @params = { :id => @offer.id, :app_id => @app.id, :offer => {} }
      end

      it 'will call with base attributes' do
        @offer.stub(:safe_update_attributes).with({}, @safe_attributes).once.and_return(true)
        put(:update, @params)
      end

      context 'when it updates properly' do
        it 'flashes a success notice' do
          @controller.instance_eval{flash.stub(:sweep)}
          @offer.stub(:safe_update_attributes).with({}, @safe_attributes).and_return(true)
          put(:update, @params)
          flash[:notice].should == 'Your offer was successfully updated.'
        end
      end

      context 'when the update fails' do
        context 'when offer has pending enable_offer_requests' do
          before :each do
            @controller.instance_eval{flash.now.stub(:sweep)}
            @offer.stub(:safe_update_attributes).with({}, @safe_attributes).and_return(false)
            mock_enable_requests = mock('enable_requests')
            mock_enable_requests.stub(:pending).and_return(['test'])
            @controller.instance_eval{flash.stub(:sweep)}
            @offer.stub(:enable_offer_requests).and_return(mock_enable_requests)
            @params = { :id => @offer.id, :app_id => @app.id, :offer => {} }
          end

          it 'assigns the first pending enable offer' do
            put(:update, @params)
            assigns(:enable_request).should == 'test'
          end

          it 'flashes an error' do
            put(:update, @params)
            flash[:error].should == 'Your offer could not be updated.'
          end
        end

        context 'when offer does not have pending enable_offer_requests' do
          before :each do
            @controller.instance_eval{flash.now.stub(:sweep)}
            @offer.stub(:safe_update_attributes).with({}, @safe_attributes).and_return(false)
            mock_enable_requests = mock('enable_requests')
            mock_enable_requests.stub(:pending).and_return(nil)
            mock_enable_requests.stub(:build).and_return('test')
            @controller.instance_eval{flash.stub(:sweep)}
            @offer.stub(:enable_offer_requests).and_return(mock_enable_requests)
          end

          it 'assigns the built enable offer' do
            put(:update, @params)
            assigns(:enable_request).should == 'test'
          end

          it 'flashes an error' do
            put(:update, @params)
            flash[:error].should == 'Your offer could not be updated.'
          end
        end
      end
    end

    context 'given a caller who is permitted to edit->dashboard_statz' do
      before :each do
        @controller.stub(:permitted_to?).with(:edit, :dashboard_statz).and_return(true)
        @controller.stub(:find_app).with(@app.id, anything).and_return(@app)
        @offer = @app.primary_offer
        @controller.stub(:log_activity).and_return(true)
        @app.stub_chain(:offers, :find).and_return(@offer)
        @params = { :id => @offer.id, :app_id => @app.id, :offer => {} }
      end

      SAFE_ATTRIBUTES = [ :daily_budget, :user_enabled, :bid, :self_promote_only,
            :min_os_version, :screen_layout_sizes, :countries, :prerequisite_offer_id,
            :exclusion_prerequisite_offer_ids, :tapjoy_enabled, :allow_negative_balance,
            :pay_per_click, :name, :name_suffix, :audition_factor, :show_rate, :min_conversion_rate,
            :device_types, :publisher_app_whitelist, :overall_budget, :min_bid_override,
            :dma_codes, :regions, :carriers, :cities, :rate_filter_override, :daily_cap_type,
            :x_partner_prerequisites, :x_partner_exclusion_prerequisites ]

      it "can update only safe atrtibutes on the related Offer" do
        @offer.stub(:safe_update_attributes) do |garbage, attributes|
          attributes.each { |attribute| SAFE_ATTRIBUTES.should include attribute }
          put(:update, @params)
        end
      end

      context "can update every safe attribute of the related Offer," do
        SAFE_ATTRIBUTES.each do |attribute|
          it "including '#{attribute}'" do
            @offer.should_receive(:safe_update_attributes) { |garbage, attributes| attributes.should include attribute }
            put(:update, @params)
          end
        end
      end
    end

    context 'when unlimited daily conversion cap gets changed to a daily limited number of installs' do
      before :each do
        @offer = @app.primary_offer
        @params = { :id           => @offer.id,
                    :app_id       => @app.id,
                    :daily_budget => 'on',
                    :offer        => { :daily_cap_type  => 'installs',
                                       :daily_budget    => '1,000' }}
      end

      it 'sets the daily cap type to :installs' do
        put :update, @params
        @offer.reload
        @offer.daily_cap_type.should == :installs
      end

      it 'saves the daily budget' do
        put :update, @params
        @offer.reload
        @offer.daily_budget.should == 1000
      end
    end

    context 'when unlimited daily conversion cap gets changed to a daily limited budget' do
      before :each do
        @offer = @app.primary_offer
        @params = { :id                   => @offer.id,
                    :app_id               => @app.id,
                    :daily_budget_toggle  => 'on',
                    :offer                => { :daily_cap_type  => 'budget',
                                               :daily_budget    => '1,000' }}
      end

      it 'sets the daily cap type to :budget' do
        put :update, @params
        @offer.reload
        @offer.daily_cap_type.should == :budget
      end
    end

    context 'when a daily limited conversion cap gets changed to an unlimited one' do
      before :each do
        @offer = @app.primary_offer
        @offer.daily_budget = 1000
        @offer.daily_cap_type = 'budget'
        @offer.save
        @controller.stub(:log_activity).with(@offer)
        @params = { :id                   => @offer.id,
                    :app_id               => @app.id,
                    :daily_budget_toggle  => 'off',
                    :offer                => {} }
      end

      it 'clears its daily cap type' do
        put :update, @params
        @offer.reload
        @offer.daily_cap_type.should be_nil
      end

      it 'zeros out its daily budget' do
        put :update, @params
        @offer.reload
        @offer.daily_budget.should be_zero
      end
    end
  end
end
