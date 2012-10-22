require 'spec_helper'

describe Dashboard::SignUpController do
  before :each do
    activate_authlogic
  end

  describe '#new' do
    it 'should guard against logged-in users' do
      user = FactoryGirl.create(:user)
      login_as(user)

      get :new

      response.should be_redirect
    end

    it 'should populate the time zone list' do
      get :new

      assigns(:zones).size.should == 6
    end
  end

  describe '#create' do
    let (:user_params) do
      { :email => 'test@example.com',
        :password => 'mega_secret',
        :password_confirmation => 'mega_secret',
        :terms_of_service => '1',
        :time_zone => 'UTC',
        :country => 'Antarctica' }
    end
    let (:post_params) do
      { :user => user_params, :partner_name => 'TestCo', :account_type_publisher => '1' }
    end

    it 'should populate user details' do
      post :create, post_params

      user = assigns(:user)
      user.username.should == 'test@example.com'
      user.email.should == 'test@example.com'
      user.time_zone.should == 'UTC'
    end

    it 'should create a new Partner' do
      post :create, post_params

      partner = assigns(:user).partners.first
      partner.name.should == 'TestCo'
      partner.contact_name.should == 'test@example.com'
      partner.country.should == 'Antarctica'
    end

    context 'success' do
      it 'should trigger a new user email' do
        post :create, post_params

        ActionMailer::Base.deliveries.last.to.should == ['test@example.com']
      end

      it 'should redirect to the apps page' do
        post :create, post_params

        response.should redirect_to(apps_path)
      end
    end

    context 'failure' do
      before :each do
        User.any_instance.stub(:save).and_return(false)
      end

      it 'should not email' do
        ActionMailer::Base.deliveries.clear

        post :create, post_params

        ActionMailer::Base.deliveries.should be_empty
      end

      it 'should redirect back to the form' do
        post :create, post_params

        response.should render_template(:new)
      end
    end
  end
end
