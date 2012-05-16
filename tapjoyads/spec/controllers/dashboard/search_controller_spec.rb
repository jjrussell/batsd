require 'spec_helper'

describe Dashboard::SearchController do
  before :each do
    activate_authlogic
  end

  describe "#gamers" do
    context 'with a non-logged in user' do
      it 'redirects to login page' do
        get :gamers
        response.should redirect_to(login_path(:goto => search_gamers_path))
      end
    end

    context 'with an unauthorized user' do
      before :each do
        @user = Factory(:agency_user)
        login_as(@user)
      end

      context 'searching for gamers' do
        it 'redirects to dashboard' do
          get :gamers
          response.should redirect_to(dashboard_root_path)
        end
      end
    end

    context 'with an admin user' do
      before :each do
        @user = Factory(:admin)
        partner = Factory(:partner, :users => [@user])
        login_as(@user)
      end

      context 'with an invalid search query' do
        it 'returns no results for blank search terms' do
          @params = { :term => '' }
          get :gamers, @params
          assigns(:gamers).count.should be_zero
        end

        it 'returns no results for queries with less than 2 characters' do
          @params = { :term => 'x' }
          get :gamers, @params
          assigns(:gamers).count.should be_zero
        end
      end

      context 'with a valid search query' do
        before :each do
          @good_gamer = Factory(:gamer, :email => "user@now.com")
          @bad_gamer = Factory(:gamer, :email => "abuser@now.com")

          @params = { :term => 'user' }
        end

        it 'returns proper results' do
          get :gamers, @params
          assigns(:gamers).should include(@good_gamer)
        end

        it 'excludes wrong results' do
          get :gamers, @params
          assigns(:gamers).should_not include(@bad_gamer)
        end

        it 'limits result count to 100' do
          # This will result in 101 matching records (since we already had one match)
          100.times do
            Factory(:gamer)
          end

          get :gamers, @params
          assigns(:gamers).count.should == 100
        end
      end
    end
  end
end
