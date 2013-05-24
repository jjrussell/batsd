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

  describe '#update' do
    before :each do
      @offer = @app.primary_offer
      @controller.stub(:log_activity).with(@offer)
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
