class Games::ConfirmationsController < GamesController
  
  def create
    @gamer = Gamer.find_using_perishable_token(params[:token], 1.year)
    if @gamer.present? && @gamer.confirm!
      flash[:notice] = 'Email address confirmed.'
      redirect_to games_root_path
    else
      flash[:error] = 'Unable to confirm email address.'
      redirect_to games_root_path
    end
  end
  
end
