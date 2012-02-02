require 'spec_helper'

describe FavoriteApp do
  before :each do
    SimpledbResource.reset_connection
    @gamer = Factory(:gamer)
    @app = Factory(:app)
  end

  it 'should add a favorite app to the gamers favorite apps' do
    FavoriteApp.add_favorite_app(@gamer.id, @app.id)
    FavoriteApp.add_favorite_app(@gamer.id, @app.id)
    @gamer.reload.favorite_apps
    FavoriteApp.new(:key => "#{@gamer.id}.#{@app.id}", :consistent => true).should_not be_new_record
  end

  it 'should delete an app from the gamers favorite apps' do
    FavoriteApp.delete_favorite_app(@gamer.id, @app.id)
    @gamer.reload.favorite_apps
    FavoriteApp.new(:key => "#{@gamer.id}.#{@app.id}", :consistent => true).should be_new_record
  end
end
