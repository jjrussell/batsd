class Games::ConfirmationsController < GamesController

  def create
    @gamer = Gamer.find_by_confirmation_token(params[:token])
    if @gamer.present? && (@gamer.confirmed_at? || @gamer.confirm!)
      flash[:notice] = 'Email address confirmed.'
      redirect_to games_root_path
    else
      flash[:error] = 'Unable to confirm email address.'
      redirect_to games_root_path
    end
  end

end
