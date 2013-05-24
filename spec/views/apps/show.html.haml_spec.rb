require 'spec_helper'

describe 'dashboard/apps/show.html.haml' do
  context 'with an admin user' do
    before :each do
      @app = assigns[:app] = FactoryGirl.create(:app)
      user = FactoryGirl.create :admin
      controller.stub(:current_user).and_return(user)
      view.stub(:current_user).and_return(user)
      render
    end

    it 'shows admin fields' do
      rendered.should have_selector 'tr.admin'
    end
  end

  context 'with a non-admin user' do
    before :each do
      @app = assigns[:app] = FactoryGirl.create(:app)
      user = FactoryGirl.create(:user, :with_partner)
      controller.stub(:current_user).and_return(user)
      view.stub(:current_user).and_return(user)
      render
    end

    it 'hides admin fields' do
      rendered.should_not have_selector 'tr.admin'
    end
  end

  context 'with an admin user' do
    before :each do
      user = FactoryGirl.create :admin
      controller.stub(:current_user).and_return(user)
      view.stub(:current_user).and_return(user)
    end

    context 'for an iOS app' do
      before :each do
        @app = FactoryGirl.create(:app)
        @app.platform = 'iphone'
        assigns[:app] = @app
        render
      end

      it 'shows the protocol handler admin field' do
        rendered.should have_selector 'input[id=app_protocol_handler]'
      end
    end

    context 'for an android app' do
      before :each do
        @app = FactoryGirl.create(:app)
        @app.platform = 'android'
        assigns[:app] = @app
        render
      end

      it 'shows the protocol handler admin field' do
        rendered.should have_selector 'input[id=app_protocol_handler]'
      end
    end

    context 'for a non-iOS/non-android app' do
      before :each do
        @app = FactoryGirl.create(:app)
        @app.platform = 'windows'
        assigns[:app] = @app
        render
      end

      it 'hides the protocol handler admin field' do
        rendered.should_not have_selector 'input[id=app_protocol_handler]'
      end
    end
  end
end
