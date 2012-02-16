class Games::Gamers::FavoriteAppController < GamesController

  before_filter :set_profile, :set_app_id

  def create
    gamer_fav_app = FavoriteApp.new(:key => "#{@gamer.id}", :consistent => true)
    unless gamer_fav_app.app_ids.include?(@app_id)
      gamer_fav_app.app_ids = @app_id
      gamer_fav_app.save
    end
    render(:json => { :success => true }) and return
  end

  def destroy
    gamer_fav_app = FavoriteApp.new(:key => "#{@gamer.id}", :consistent => true)
    if gamer_fav_app.app_ids.include?(@app_id)
      gamer_fav_app.delete('app_ids', @app_id)
      gamer_fav_app.save
    end
    render(:json => { :success => true }) and return
  end

  private

  def set_app_id
    render_json_error(['An app_id must be provided']) and return if params[:app_id].blank?
    @app_id = params[:app_id]
  end

end
