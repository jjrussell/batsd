require 'spec_helper'

describe Dashboard::NonRewardedController do
  before :each do
    activate_authlogic
    @user = FactoryGirl.create(:user)
    login_as(@user)
    @app = FactoryGirl.create(:app)
    @partner = @app.partner

    App.any_instance.stub(:build_non_rewarded) do
       FactoryGirl.create(:currency,
        :conversion_rate  => 0,
        :callback_url     => Currency::NO_CALLBACK_URL,
        :name             => Currency::NON_REWARDED_NAME,
        :app_id           => @app.id,
        :tapjoy_enabled   => false,
        :partner          => @partner
      )
    end

    App.any_instance.stub(:partner).and_return(@partner)
    App.stub(:find).and_return(@app)
    @params = { :app_id => @app.id }
  end

  describe '#show' do
    context 'when no non-rewarded currency exists' do
      before :each do
        get(:show, @params)
      end

      it 'renders the #new action' do
        response.should render_template(:new)
      end
    end

    context 'when a non-rewarded currency exists' do
      before :each do
        @app.build_non_rewarded
        get(:show, @params)
      end

      it 'renders the #edit action' do
        response.should render_template(:edit)
      end
    end
  end

  describe '#new' do
    context 'when no non-rewarded currency exists' do
      before :each do
        get(:new, @params)
      end

      it 'renders the #new action' do
        response.should render_template(:new)
      end
    end

    context 'when a non-rewarded currency exists' do
      before :each do
        @app.build_non_rewarded
        get(:new, @params)
      end

      it 'redirects to the #edit action' do
        response.should redirect_to(edit_app_non_rewarded_path(:app_id => @app.id))
      end
    end
  end

  describe '#edit' do
    context 'when no non-rewarded currency exists' do
      before :each do
        get(:edit, @params)
      end

      it 'redirects to the #new action' do
        response.should redirect_to(new_app_non_rewarded_path(:app_id => @app.id))
      end
    end

    context 'when a non-rewarded currency exists' do
      before :each do
        @app.build_non_rewarded
        get(:edit, @params)
      end

      it 'renders the #edit action' do
        response.should render_template(:edit)
      end
    end
  end

  describe '#create' do
    context 'when the partner has not already accepted the publisher TOS' do
      before :each do
        @partner.accepted_publisher_tos = false
      end

      context 'and the agreement checkbox was not checked' do
        before(:each) do
          post(:create, @params)
        end

        it 'flashes an error' do
          flash[:error].should == 'You must accept the terms of service to set up non-rewarded.'
        end

        it 'redirects to #show' do
          response.should redirect_to app_non_rewarded_path(:app_id => @app.id)
        end
      end

      context 'but the agreement box was checked' do
        before :each do
          @params[:terms_of_service] = '1'
        end

        after :each do
          post(:create, @params)
        end

        it 'writes @partner to the activity log' do
          Dashboard::NonRewardedController.any_instance.should_receive(:log_activity).with(@partner)
        end

        it 'updates @partner.accepted_publisher_tos' do
          @partner.should_receive(:update_attribute).with(:accepted_publisher_tos, true)
        end
      end
    end

    context 'when the partner has accepted the publisher TOS' do
      before :each do
        @partner.accepted_publisher_tos = true
      end

      context 'and a non-rewarded already exists' do
        it 'does not build another non-rewarded' do
          @app.should_not_receive(:build_non_rewarded)
        end
      end

      context 'and a non-rewarded does not yet exist' do
        it 'builds a new non-rewarded' do
          App.any_instance.should_receive(:build_non_rewarded)
          post(:create, @params)
        end

        it 'saves the new non-rewarded' do
          post(:create, @params)
          @app.reload.non_rewarded.should be
        end

        context 'when @currency.save is successful' do
          before :each do
            Currency.any_instance.stub(:save).and_return(true)
            post(:create, @params)
          end

          it 'flashes a notice alerting the user that the non-rewarded was created' do
            flash[:notice].should == "Non-rewarded has been created."
          end

          it 'redirects to #show' do
            response.should redirect_to(app_non_rewarded_path(:app_id => @app.id))
          end
        end

        context 'when @currency.save is unsuccessful' do
          before :each do
            Currency.any_instance.stub(:save).and_return(false)
            post(:create, @params)
          end

          it 'flashes an error and redirects to #show' do
            flash.now[:error].should == "Could not create non-rewarded."
            response.should redirect_to(app_non_rewarded_path(:app_id => @app.id))
          end
        end
      end
    end
  end

  describe '#update' do
    before :each do
      @params[:currency] = { :test_devices => 'this_is_a_fake_test_device' }
    end

    context 'when a non-rewarded does not exist' do
      it 'redirects to #new' do
        post(:update, @params)
        response.should redirect_to(new_app_non_rewarded_path(:app_id => @app.id))
      end
    end

    context 'when a non-rewarded does exist' do
      before :each do
        @editable_attribs_for_users = [ :test_devices, :minimum_offerwall_bid, :minimum_featured_bid, :minimum_display_bid ]
        @editable_attribs_for_admins = @editable_attribs_for_users + [ :tapjoy_enabled, :hide_rewarded_app_installs, :disabled_offers, :max_age_rating, :only_free_offers, :send_offer_data, :ordinal, :rev_share_override, :message, :message_enabled, :conversion_rate_enabled ]
        @app.build_non_rewarded.save
        @app.save
      end

      it 'finishes up by redirecting to NonRewardedController#show' do
        post(:update, @params)
        response.should redirect_to(app_non_rewarded_path(:app_id => @app.id))
      end

      context 'and the user attempts to update fields they lack authorization for' do
          before :each do
            @params[:currency][:tapjoy_enabled] = true
            post(:update, @params)
          end

          it 'flashes an error' do
            flash.now[:error].should == "Could not update non-rewarded."
          end

          it 'redirects to NonRewardedController#show' do
            response.should redirect_to(app_non_rewarded_path(:app_id => @app.id))
          end
        end
      end

      context 'and the user attempts to update fields they have authorization for' do
        before :each do
          @app.build_non_rewarded.save
          @app.save
          @before = @app.non_rewarded
          @before_test_devices = @before.test_devices.clone
          post(:update, @params)
          @after = @app.non_rewarded
        end

        it 'updates the non-rewarded' do
          @before.id.should == @after.id
          @before_test_devices.should_not == @after.test_devices
        end

        it 'flashes a success message' do
          flash[:notice].should == "Non-rewarded has been updated."
        end
      end
    end
  end
