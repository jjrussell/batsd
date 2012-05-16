require 'spec_helper'

describe Dashboard::Tools::BrandsController do
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
    before :each do
      @brand = Factory(:brand)
    end

    context 'when normal user' do
      before :each do
        @user = Factory(:user)
        login_as(@user)
      end

      it 'will not create new brand name' do
        Brand.expects(:new).with(:name => 'test').never
        post(:create, :brand => { :name => 'test'}, :format => 'json')
      end
      it 'will not succeed' do
        post(:create, :brand => { :name => 'test'}, :format => 'json')
        response.should_not be_success
      end
    end

    context 'when account manager role' do
      before :each do
        @user = Factory(:account_mgr_user)
        login_as(@user)
      end

      context 'when a brand name is supplied' do
        it 'will succeed' do
          Brand.expects(:new).with(:name => 'test').once.returns(@brand)
          post(:create, :brand => { :name => 'test'}, :format => 'json')
          JSON.parse(response.body)['success'].should be_true
        end
      end

      context 'when a brand name is not supplied' do
        it 'will not succeed' do
          @brand.name = ''
          @brand.stubs(:save).returns(false)
          Brand.expects(:new).with( :name => '').once.returns(@brand)
          post(:create, :brand => { :name => ''}, :format => 'json')
          JSON.parse(response.body)['success'].should be_false
        end
      end
    end
  end



  describe '#show' do
    context 'when normal user' do
      before :each do
        @user = Factory(:user)
        login_as(@user)
      end

      it 'will not call find on Brand' do
        Brand.expects(:find).with(:id => '123').never
        get(:show, :id => '123')
      end

      it 'will not succeed' do
        get(:offers, :id => '123')
        response.should_not be_success
      end
    end

    context 'when account manager role' do
      before :each do
        @user = Factory(:account_mgr_user)
        login_as(@user)
        @brand = Factory(:brand)
        @offer = Factory(:app).primary_offer
        @brand.stubs(:offers).returns([@offer])
      end

      context 'when brand id is valid' do
        before :each do
          Brand.stubs(:find).with(@brand.id).returns(@brand)
        end

        it 'will list associated offers' do
          get(:show, :id => @brand.id)
          response.body.should == [{:id => @offer.id, :name => @offer.search_result_name}].to_json
        end

        it 'will succeed' do
          get(:show, :id => @brand.id)
          response.should be_success
        end
      end
    end
  end

end
