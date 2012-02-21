require 'spec/spec_helper'

describe Games::Gamers::FavoriteAppController do
  before :each do
    activate_authlogic
    @app = Factory(:app)
    @gamer = Factory(:gamer)
    @controller.stubs(:current_gamer).returns(@gamer)

    @params = {
      :app_id => @app.id,
    }
  end

  describe '#create' do
    it 'fails when no app is provided' do
      get('create')
      should_respond_with_json_error(403)
    end

    it 'fails when an invalid app is provided' do
      get('create', { :app_id => 'NOT_A_GUID' })
      should_respond_with_json_error(403)
    end

    it 'fails if it is unable to save' do
      FavoriteApp.any_instance.stubs(:save).returns(false)
      get('create', @params)
      should_respond_with_json_error(403)
    end

    it 'adds the app to the gamers favorite apps' do
      get('create', @params)
      should_respond_with_json_success(200)
      @gamer.favorite_apps.map(&:app_id).should include(@app.id)
    end

    it 'keeps a unique list of favorite apps' do
      get('create', @params)
      should_respond_with_json_success(200)
      num_apps = @gamer.favorite_apps.length
      get('create', @params)
      should_respond_with_json_success(200)
      assert_equal(@gamer.favorite_apps.length, num_apps)
    end
  end

  describe '#destroy' do
    it 'returns failure when no app is provided' do
      get('destroy')
      should_respond_with_json_error(403)
    end

    it 'deletes the app from the gamers favorite apps' do
      get('create', @params)
      should_respond_with_json_success(200)
      get('destroy', @params)
      should_respond_with_json_success(200)
      @gamer.favorite_apps.map(&:app_id).should_not include(@app.id)
    end
  end
end
