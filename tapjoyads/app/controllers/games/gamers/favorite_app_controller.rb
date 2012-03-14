class Games::Gamers::FavoriteAppController < GamesController

  before_filter :require_gamer, :require_eapp_metadata

  def create
    fav_app = current_gamer.favorite_apps.find_or_initialize_by_app_metadata_id(@app_metadata_id)
    if fav_app.new_record? && !fav_app.save
      render_json_error(['Error encountered creating a favorite app']) and return
    end
    render(:json => { :success => true })
  end

  def destroy
    fav_app = current_gamer.favorite_apps.find_by_app_metadata_id(@app_metadata_id)
    fav_app.destroy if fav_app.present?
    render(:json => { :success => true })
  end

  private

  def require_eapp_metadata
    unless verify_params([:eapp_metadata_id], :render_missing_text => false)
      render_json_error(['An encrypted app_metadata_id must be provided']) and return
    end
    begin
      @app_metadata_id = ObjectEncryptor.decrypt(params[:eapp_metadata_id])
    rescue
      render_json_error(['Invalid encrypted app_metadata_id']) and return
    end
  end

end
