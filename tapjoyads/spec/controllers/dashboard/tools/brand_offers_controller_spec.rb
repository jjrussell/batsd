require 'spec_helper'

describe Dashboard::Tools::BrandOffersController do
  before :each do
    fake_the_web
    activate_authlogic
  end

  describe '#index' do
    context 'when normal user' do
      before :each do
        @user = Factory(:user)
        login_as(@user)
      end

      it 'will not succeed' do
        get(:index)
        response.should_not be_success
      end

    end

    context 'when account manager role' do
      it 'will succeed' do
        @user = Factory(:account_mgr_user)
        login_as(@user)
        get(:index)
        response.should be_success
      end
    end
  end

  describe '#create' do
    context 'when normal user' do
      before :each do
        @user = Factory(:user)
        login_as(@user)
      end

      it 'will not call find on Brand' do
        Brand.should_receive(:find).with('123').never
        post(:create, :brand => '123')
      end

      it 'will not succeed' do
        post(:create, :brand => '123')
        response.should_not be_success
      end
    end

    context 'when account manager role' do
      before :each do
        @user = Factory(:account_mgr_user)
        login_as(@user)
      end

      context 'when offer id is valid' do
        before :each do
          @offer = Factory(:app).primary_offer
          @brand = Factory(:brand)
          @brand_offer_mapping = mock()
          BrandOfferMapping.stub(:new).with(:brand_id => @brand.id, :offer_id => @offer.id).and_return(@brand_offer_mapping)
        end

        it 'will add the offer' do
          @brand_offer_mapping.should_receive(:save).once.and_return(true)
          post(:create, :brand => @brand.id, :offer => @offer.id)
        end

        it 'will succeed' do
          @brand_offer_mapping.stub(:save).and_return(true)
          post(:create, :brand => @brand.id, :offer => @offer.id)
          JSON.parse(response.body)['success'].should be_true
        end
      end
    end
  end

  describe '#delete' do
    context 'when normal user' do
      before :each do
        @user = Factory(:user)
        login_as(@user)
      end

      it 'will not call find on Brand' do
        BrandOfferMapping.should_receive(:find_by_brand_id_and_offer_id).with('123', '456').never
        post(:delete, :brand => '123', :offer => '456')
      end

      it 'will not succeed' do
        post(:delete, :brand => '123', :offer => '456')
        response.should_not be_success
      end
    end

    context 'when account manager role' do
      before :each do
        @user = Factory(:account_mgr_user)
        login_as(@user)
      end

      context 'when offer id is valid' do
        before :each do
          @offer = Factory(:app).primary_offer
          @brand = Factory(:brand)
          @brand_offer_mapping = mock()
          BrandOfferMapping.stub(:find_by_brand_id_and_offer_id).with(@brand.id, @offer.id).and_return(@brand_offer_mapping)
        end

        it 'will remove the offer' do
          @brand_offer_mapping.should_receive(:destroy).once.and_return(true)
          post(:delete, :brand => @brand.id, :offer => @offer.id)
        end

        it 'will succeed' do
          @brand_offer_mapping.stub(:destroy).and_return(true)
          post(:delete, :brand => @brand.id, :offer => @offer.id)
          JSON.parse(response.body)['success'].should be_true
        end
      end
    end
  end
end
