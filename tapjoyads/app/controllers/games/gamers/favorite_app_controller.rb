class Games::Gamers::FavoriteAppController < GamesController

  before_filter :require_gamer, :set_app_id

  def create
    fav_app = get_favorite_app(@app_id) || FavoriteApp.new(:gamer => current_gamer, :app_id => @app_id)
    if fav_app.new_record? && !fav_app.save
      render_json_error(['Error encountered creating a favorite app']) and return
    end
    render(:json => { :success => true }) and return
  end

  def destroy
    FavoriteApp.delete(get_favorite_app(@app_id))
    render(:json => { :success => true }) and return
  end

  private

  def get_favorite_app(app_id)
    current_gamer.favorite_apps.find_by_app_id(app_id)
  end

  def set_app_id
    render_json_error(['An app_id must be provided']) and return if params[:app_id].blank?
    @app_id = params[:app_id]
  end

end
