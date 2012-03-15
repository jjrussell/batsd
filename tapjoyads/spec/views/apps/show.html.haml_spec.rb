require 'spec/spec_helper'

describe 'apps/show.html.haml' do
  context 'with an admin user' do
    before :each do
      assigns[:app] = Factory :app
      user = Factory :admin
      controller.stubs(:current_user).returns(user)
      template.stubs(:current_user).returns(user)
      render
    end

    it 'shows admin fields' do
      response.should have_tag 'tr.admin'
    end
  end

  context 'with a non-admin user' do
    before :each do
      assigns[:app] = Factory :app
      user = Factory :partner_user
      controller.stubs(:current_user).returns(user)
      template.stubs(:current_user).returns(user)
      render
    end

    it 'hides admin fields' do
      response.should_not have_tag 'tr.admin'
    end
  end

  context 'with an admin user' do
    before :each do
      user = Factory :admin
      controller.stubs(:current_user).returns(user)
      template.stubs(:current_user).returns(user)
    end

    context 'for an iOS app' do
      before :each do
        app = Factory :app
        app.platform = 'iphone'
        assigns[:app] = app
        render
      end

      it 'shows the protocol handler admin field' do
        response.should have_tag 'input[id=app_protocol_handler]'
      end
    end

    context 'for a non-iOS app' do
      before :each do
        app = Factory :app
        app.platform = 'android'
        assigns[:app] = app
        render
      end

      it 'hides the protocol handler admin field' do
        response.should_not have_tag 'input[id=app_protocol_handler]'
      end
    end
  end
end
