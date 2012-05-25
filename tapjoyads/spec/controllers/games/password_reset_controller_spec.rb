require 'spec_helper'

describe Games::PasswordResetController do
  describe 'going to /password-reset' do
    describe 'using GET' do
      it 'renders new' do
        path = { :controller => 'games/password_reset', :action => 'new' }
        { :get => "/games/password-reset" }.should route_to path
      end
    end

    describe 'using POST' do
      it 'renders create' do
        path = { :controller => 'games/password_reset', :action => 'create' }
        { :post => "/games/password_reset" }.should route_to path
      end

      it 'sends email' do
        gamer = Factory(:gamer)
        GamesMailer.expects(:deliver_password_reset).once
        post(:create, :email => gamer.email)

        response.should render_template("new")
      end
    end
  end
end
