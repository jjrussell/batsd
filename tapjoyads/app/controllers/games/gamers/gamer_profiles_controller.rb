class Games::Gamers::GamerProfilesController < GamesController

  before_filter :set_profile, :only => [ :edit, :update, :update_birthdate ]

  def update
    @gamer_profile.safe_update_attributes(params[:gamer_profile], [ :name, :nickname, :gender, :city, :country, :postal_code, :favorite_game, :favorite_category ])
    if @gamer_profile.save
      redirect_to edit_games_gamer_path
    else
      flash.now[:error] = 'Error updating profile'
      render :action => :edit
    end
  end

  def update_birthdate
    @gamer_profile.birthdate = Date.new(params[:date][:year].to_i, params[:date][:month].to_i, params[:date][:day].to_i)
    if @gamer_profile.save
      render(:json => { :success => true }) and return
    else
      @gamer_profile.errors.each do |attribute, error|
        if attribute == 'birthdate'
          @gamer.blocked = true
          @gamer.save!
        end
      end
      render(:json => { :success => false, :error => @gamer_profile.errors }) and return
    end
  end

private
  def set_profile
    if current_gamer.present?
      @gamer = current_gamer
      @gamer_profile = @gamer.gamer_profile || GamerProfile.new(:gamer => @gamer)
    else
      flash[:error] = "Please log in and try again. You must have cookies enabled."
      redirect_to games_root_path
    end
  end
end

