class Games::Gamers::GamerProfilesController < GamesController

  before_filter :set_profile, :only => [ :edit, :update ]

  def update
    @gamer_profile.gamer_id = params[:gamer_id]
    @gamer_profile.safe_update_attributes(params[:gamer_profile], [ :first_name, :last_name, :gender, :city, :country, :favorite_game ])
    if @gamer_profile.save
      redirect_to edit_games_gamer_path
    else
      flash.now[:error] = 'Error updating profile'
      render :action => :edit
    end
  end

private
  def set_profile
    if current_gamer.present?
      @gamer = current_gamer
      @gamer_profile = @gamer.gamer_profile || GamerProfile.new
    else
      flash[:error] = "Please log in and try again. You must have cookies enabled."
      redirect_to games_root_path
    end
  end
end

