require 'spec_helper'

describe Dashboard::Tools::OptimizedRankBoostsController do
  before :each do
    activate_authlogic
    optimized = FactoryGirl.create(:optimized_rank_booster)
    @partner = FactoryGirl.create(:partner, :id => TAPJOY_PARTNER_ID)
    optimized.partners << @partner
    login_as(optimized)
  end

  describe 'rank boost object amount too high' do
    before :each do
      @rank_boost = FactoryGirl.build(:rank_boost, :optimized => true, :amount => 4000)
      @rank_boost.valid?
    end
    it 'should not be valid (amount > 1000)' do
      @rank_boost.should_not be_valid
    end
    it 'should have errors' do
      @rank_boost.errors[:amount].should include("Amount must be <= #{RankBoost::OPTIMIZED_RANK_BOOST_MAX}")
    end
  end

  describe '#index' do
    context 'with an offer' do
      context 'active rank boosts' do
        before :each do
          @rank_boost = FactoryGirl.create(:rank_boost, :optimized => true)
          RankBoost.stub(:find).and_return(@rank_boost)
          @offer = @rank_boost.offer
          @params = { :filter => 'active', :id => @rank_boost.id, :page => 1 }
          get(:index, @params)
        end
        it 'should have optimized_rank_boosts instance variable' do
          assigns(:optimized_rank_boosts).should == [@rank_boost]
        end
        it 'should have an offer instance variable' do
          assigns(:offer).should == @offer
        end
        it 'responds with 200' do
          should respond_with 200
        end
      end
      context 'no active rank boosts' do
        context 'with active param passed in' do
          before :each do
            @rank_boost = FactoryGirl.create(:rank_boost, :optimized => true, :start_time => Time.zone.now + 2.days, :end_time => Time.zone.now + 3.days)
            RankBoost.stub(:find).and_return(@rank_boost)
            @offer = @rank_boost.offer
            @params = { :filter => 'active', :id => @rank_boost.id, :page => 1 }
            get(:index, @params)
          end
          it 'should have optimized_rank_boosts instance variable' do
            assigns(:optimized_rank_boosts).should == []
          end
          it 'should have an offer instance variable' do
            assigns(:offer).should == @offer
          end
          it 'responds with 200' do
            should respond_with 200
          end
        end
        context 'without active param passed in' do
          before :each do
            @rank_boost = FactoryGirl.create(:rank_boost, :optimized => true, :start_time => Time.zone.now + 2.days, :end_time => Time.zone.now + 3.days)
            RankBoost.stub(:find).and_return(@rank_boost)
            @offer = @rank_boost.offer
            @params = { :id => @rank_boost.id, :page => 1 }
            get(:index, @params)
          end
          it 'should have optimized_rank_boosts instance variable' do
            assigns(:optimized_rank_boosts).should == [@rank_boost]
          end
          it 'should have an offer instance variable' do
            assigns(:offer).should == @offer
          end
          it 'responds with 200' do
            should respond_with 200
          end
        end
      end
    end
    context 'without an offer' do
      context 'active rank boosts' do
        before :each do
          @rank_boost = FactoryGirl.create(:rank_boost, :optimized => true)
          @params = { :filter => 'active', :page => 1 }
          get(:index, @params)
        end
        it 'should have optimized_rank_boosts instance variable' do
          assigns(:optimized_rank_boosts).should == [@rank_boost]
        end
        it 'should have a nil offer instance variable' do
          assigns(:offer).should be_nil
        end
        it 'responds with 200' do
          should respond_with 200
        end
      end
      context 'no active rank boosts' do
        context 'with active param passed in' do
          before :each do
            @rank_boost = FactoryGirl.create(:rank_boost, :optimized => true, :start_time => Time.zone.now + 2.days, :end_time => Time.zone.now + 3.days)
            @offer = @rank_boost.offer
            @params = { :filter => 'active', :page => 1 }
            get(:index, @params)
          end
          it 'should have optimized_rank_boosts instance variable' do
            assigns(:optimized_rank_boosts).should == []
          end
          it 'should have a nil offer instance variable' do
            assigns(:offer).should be_nil
          end
          it 'responds with 200' do
            should respond_with 200
          end
        end
        context 'without active param passed in' do
          before :each do
            @rank_boost = FactoryGirl.create(:rank_boost, :optimized => true, :start_time => Time.zone.now + 2.days, :end_time => Time.zone.now + 3.days)
            @offer = @rank_boost.offer
            @params = { :page => 1 }
            get(:index, @params)
          end
          it 'should have optimized_rank_boosts instance variable' do
            assigns(:optimized_rank_boosts).should == [@rank_boost]
          end
          it 'should have a nil offer instance variable' do
            assigns(:offer).should be_nil
          end
          it 'responds with 200' do
            should respond_with 200
          end
        end
      end
    end
  end

  describe '#new' do
    context 'with offer' do
      before :each do
        @offer = FactoryGirl.create(:app).primary_offer
        Offer.stub(:find).and_return(@offer)
        @params = { :offer_id => @offer.id }
        get(:new, @params)
      end
      it 'responds with 200' do
        should respond_with 200
      end
      it 'should have an offer instance variable' do
        assigns(:offer).should == @offer
      end
      it 'should have an optimized_rank_boost instance variable set with offer' do
        assigns(:optimized_rank_boost).offer.should == @offer
      end
    end
    context 'without offer' do
      before :each do
        @params = {}
        @rank_boost = double(RankBoost)
        RankBoost.stub(:new).and_return(@rank_boost)
        get(:new, @params)
      end
      it 'responds with 200' do
        should respond_with 200
      end
      it 'should have a nil offer instance variable' do
        assigns(:offer).should be_nil
      end
      it 'has optimized_rank_boost instance variable' do
        assigns(:optimized_rank_boost).should == @rank_boost
      end
    end
  end

  describe '#create' do
    context 'valid' do
      before :each do
        RankBoost.any_instance.stub(:save).and_return(true)
        @rank_boost = FactoryGirl.build(:rank_boost, :optimized => true)
        RankBoost.stub(:new).and_return(@rank_boost)
        @params = { :rank_boost =>
                    { :start_time => @rank_boost.start_time,
                      :end_time => @rank_boost.end_time,
                      :optimized => @rank_boost.optimized,
                      :offer_id => @rank_boost.offer.id,
                      :amount => @rank_boost.amount } }
        post(:create, @params)
      end
      it 'has a flash notice' do
        flash[:notice].should == 'Optimized Rank Boost created.'
      end
      it 'redirects to offer\'s offer page' do
        response.should redirect_to(statz_path(@rank_boost.offer_id))
      end
    end
    context 'invalid' do
      context 'unable to save rank boost object' do
        before :each do
          RankBoost.any_instance.stub(:save).and_return(false)
          @rank_boost = FactoryGirl.build(:rank_boost, :optimized => true)
          RankBoost.stub(:new).and_return(@rank_boost)
          @params = { :rank_boost =>
                      { :start_time => @rank_boost.start_time,
                        :end_time => @rank_boost.end_time,
                        :optimized => @rank_boost.optimized,
                        :offer_id => @rank_boost.offer.id,
                        :amount => @rank_boost.amount } }
          post(:create, @params)
        end
        it 'it renders new page' do
          response.should render_template('new')
        end
      end
      context 'offer is not present' do
        before :each do
          @rank_boost = FactoryGirl.build(:rank_boost, :optimized => true)
          @params = { :rank_boost =>
                      { :start_time => @rank_boost.start_time,
                        :end_time => @rank_boost.end_time,
                        :optimized => @rank_boost.optimized,
                        :amount => @rank_boost.amount } }
          RankBoost.stub(:new).and_return(@rank_boost)
          Offer.stub(:find).and_return(nil)
          post(:create, @params)
        end
        it 'has a flash error message' do
          flash[:error].should == "Offer can't be blank."
        end
        it 'renders new page' do
          response.should render_template('new')
        end
      end
    end
  end

  describe '#edit' do
    before :each do
      @rank_boost = FactoryGirl.create(:rank_boost, :optimized => true)
      RankBoost.stub(:find).and_return(@rank_boost)
      @params = { :id => @rank_boost.id }
      get(:edit, @params)
    end
    it 'has an optimized_rank_boost instance variable' do
      assigns(:optimized_rank_boost).should == @rank_boost
    end
    it 'has an offer instance variable' do
      assigns(:offer).should == @rank_boost.offer
    end
    it 'responds with 200' do
      should respond_with 200
    end
  end

  describe '#update' do
    context 'valid' do
      before :each do
        RankBoost.any_instance.stub(:update_attributes).and_return(true)
        @rank_boost = FactoryGirl.create(:rank_boost, :optimized => true)
        @params = { :rank_boost =>
                    { :amount => 10 },
                    :id => @rank_boost.id }
        put(:update, @params)
      end
      it 'has a flash notice' do
        flash[:notice].should == 'Optimized Rank Boost updated.'
      end
      it 'redirects to offer\'s statz page' do
        response.should redirect_to(statz_path(@rank_boost.offer_id))
      end
    end
    context 'invalid' do
      context 'unable to update rank boost object' do
        before :each do
          RankBoost.any_instance.stub(:update_attributes).and_return(false)
          @rank_boost = FactoryGirl.create(:rank_boost, :optimized => true)
          @params = { :rank_boost =>
                      { :amount => 10 },
                      :id => @rank_boost.id }
          put(:update, @params)
        end
        it 'redirects to offer\'s statz page' do
          should render_template('edit')
        end
      end
      context 'offer is not present' do
        before :each do
          @rank_boost = FactoryGirl.create(:rank_boost, :optimized => true)
          @params = { :rank_boost =>
                      { :amount => 10 },
                      :id => @rank_boost.id }
          Offer.stub(:find).and_return(nil)
          put(:update, @params)
        end
        it 'has a flash error message' do
          flash[:error].should == "Offer can't be blank."
        end
        it 'renders new page' do
          response.should render_template('edit')
        end
      end
    end
  end

  describe '#deactivate' do
    context 'valid deactivation' do
      before :each do
        RankBoost.any_instance.stub(:deactivate!).and_return(true)
        @rank_boost = FactoryGirl.create(:rank_boost, :optimized => true)
        @params = { :id => @rank_boost.id, :offer_id => @rank_boost.offer.id }
        post(:deactivate, @params)
      end
      it 'has a flash notice' do
        flash[:notice].should == 'Optimized Rank Boost deactivated.'
      end
      it 'redirects to offer\'s statz page' do
        response.should redirect_to(statz_path(@rank_boost.offer_id))
      end
    end
    context 'invalid deactivation' do
      before :each do
        RankBoost.any_instance.stub(:deactivate!).and_return(false)
        @rank_boost = FactoryGirl.create(:rank_boost, :optimized => true)
        @params = { :id => @rank_boost.id, :offer_id => @rank_boost.offer.id }
        post(:deactivate, @params)
      end
      it 'has a flash error' do
        flash[:error].should == 'Optimized Rank Boost could not be deactivated.'
      end
      it 'redirects to offer\'s statz page' do
        response.should redirect_to(statz_path(@rank_boost.offer_id))
      end
    end
  end
end
