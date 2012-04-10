class Games::ConfirmationsController < GamesController

  def create
    @gamer = Gamer.find_by_confirmation_token(params[:token])
    path   = games_root_path
    if @gamer.present? && (@gamer.confirmed_at? || @gamer.confirm!)
      flash[:notice] = 'Email address confirmed.'
      path = games_root_path(:utm_campaign => 'email_confirm',
                             :utm_medium   => 'email',
                             :utm_source   => 'tapjoy',
                             :utm_content  => params[:content]) if  params[:content].present?
      redirect_to path
    else
      flash[:error] = 'Unable to confirm email address.'
      redirect_to path
    end
  end

end
