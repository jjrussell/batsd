require 'spec/spec_helper'

describe Games::FavoriteAppController do
  include Authlogic::TestCase

  before :each do
    activate_authlogic
    @app_metadata = Factory(:app_metadata)

    @gamer = Factory(:gamer)
    @controller.stubs(:current_gamer).returns(@gamer)

    @params = {
      :eapp_metadata_id => ObjectEncryptor.encrypt(@app_metadata.id)
    }
  end

  describe '#create' do
    context 'when no app_metadata is provided' do
      before :each do
        post('create')
      end

      it 'returns an error' do
        should_respond_with_json_error(403)
      end
    end

    context 'when an invalid app_metadata is provided' do
      before :each do
        post('create', { :eapp_metadata_id => 'NOT_A_VALID_VALUE' })
      end

      it 'returns an error' do
        should_respond_with_json_error(403)
      end
    end

    context 'when unable to save' do
      before :each do
        FavoriteApp.any_instance.stubs(:save).returns(false)
        post('create', @params)
      end

      it 'returns an error' do
        should_respond_with_json_error(403)
      end
    end

    it 'adds the app_metadata to the gamers favorite apps' do
      post('create', @params)
      should_respond_with_json_success(200)
      @gamer.favorite_apps.map(&:app_metadata_id).should include(@app_metadata.id)
    end

    it 'keeps a unique list of favorite apps' do
      post('create', @params)
      should_respond_with_json_success(200)
      num_apps = @gamer.favorite_apps.length
      post('create', @params)
      should_respond_with_json_success(200)
      @gamer.favorite_apps.length.should == num_apps
    end
  end

  describe '#destroy' do
    context 'when no app_metadata is provided' do
      before :each do
        delete('destroy')
      end

      it 'returns an error' do
        should_respond_with_json_error(403)
      end
    end

    it 'deletes the app_metadata from the gamers favorite apps' do
      post('create', @params)
      should_respond_with_json_success(200)
      delete('destroy', @params)
      should_respond_with_json_success(200)
      @gamer.favorite_apps.map(&:app_metadata_id).should_not include(@app_metadata.id)
    end
  end
end
