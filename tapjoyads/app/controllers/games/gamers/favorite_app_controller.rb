class Games::Gamers::FavoriteAppController < GamesController

  before_filter :require_gamer, :require_app

  def create
    fav_app = current_gamer.favorite_apps.find_or_initialize_by_app_id(params[:app_id])
    if fav_app.new_record? && !fav_app.save
      render_json_error(['Error encountered creating a favorite app']) and return
    end
    render(:json => { :success => true })
  end

  def destroy
    fav_app = current_gamer.favorite_apps.find_by_app_id(params[:app_id])
    fav_app.destroy if fav_app.present?
    render(:json => { :success => true })
  end

  private

  def require_app
    unless verify_params([:app_id], :render_missing_text => false)
      render_json_error(['An app_id must be provided'])
    end
  end

end
