class Games::GamerProfilesController < GamesController

  before_filter :set_profile, :only => [ :show, :edit, :update, :update_birthdate, :update_prefs, :dissociate_account ]

  def update
    @gamer_profile.safe_update_attributes(params[:gamer_profile], [ :name, :nickname, :gender, :city, :country, :postal_code, :favorite_game, :favorite_category ])
    if @gamer_profile.save
      flash[:notice] = t('text.games.profile_update')
      redirect_to games_gamer_profile_path(@gamer_profile)
    else
      flash[:error] = t('text.games.profile_error')
      redirect_to edit_games_gamer_profile_path(@gamer_profile)
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

  def dissociate_account
    channel = params[:account_type].present? ? params[:account_type].to_i : Invitation::FACEBOOK
    begin
      @gamer_profile.dissociate_account!(channel)
      redirect_to games_social_index_path(:fb_logout => 'true')
    rescue
      flash[:error] = t('text.games.failed_to_change_linked')
      redirect_to games_social_index_path
    end
  end

  def update_prefs
    @gamer_profile.allow_marketing_emails = params[:gamer_profile][:allow_marketing_emails]
    if @gamer_profile.save
      redirect_to edit_games_gamer_path
    else
      flash[:error] = 'Error updating preferences'
      redirect_to :controller => '/games/gamers', :action => :prefs
    end
  end

  def show
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

