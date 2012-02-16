require 'spec/spec_helper'

describe Games::Gamers::FavoriteAppController do
  before :each do
    activate_authlogic
    @app_id = Factory.next(:guid)
    @gamer = Factory(:gamer)
    @controller.stubs(:current_gamer).returns(@gamer)

    @params = {
      :app_id => @app_id,
    }
  end

  describe 'create' do
    it 'returns failure when no app is provided' do
      get('create')
      should_respond_with_json_error(403)
    end

    it 'adds the app to the gamers favorite apps' do
      get('create', @params)
      should_respond_with_json_success(200)
      gamer_fav = FavoriteApp.new(:key => @gamer.id, :consistent => true)
      gamer_fav.should_not be_new_record
      gamer_fav.app_ids.should include(@app_id)
    end

    it 'keeps a unique list of favorite apps' do
      get('create', @params)
      should_respond_with_json_success(200)
      num_apps = FavoriteApp.new(:key => @gamer.id, :consistent => true).app_ids.length
      get('create', @params)
      should_respond_with_json_success(200)
      assert_equal(FavoriteApp.new(:key => @gamer.id, :consistent => true).app_ids.length, num_apps)
    end
  end

  describe 'destroy' do
    it 'returns failure when no app is provided' do
      get('destroy')
      should_respond_with_json_error(403)
    end

    it 'deletes the app from the gamers favorite apps' do
      get('create', @params)
      should_respond_with_json_success(200)
      get('destroy', @params)
      should_respond_with_json_success(200)
      gamer_fav = FavoriteApp.new(:key => @gamer.id, :consistent => true)
      gamer_fav.app_ids.should_not include(@app_id)
    end
  end
end
