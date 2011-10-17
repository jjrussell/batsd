class Games::PasswordResetsController < GamesController

  before_filter :require_no_gamer
  before_filter :find_gamer_using_perishable_token, :only => [ :edit, :update ]

  def new
  end

  def create
    @gamer = Gamer.find_by_email(params[:email])
    if @gamer.present?
      @gamer.reset_perishable_token!
      GamesMailer.deliver_password_reset(@gamer, edit_games_password_reset_url(@gamer.perishable_token))
      flash.now[:notice] = "A password reset link has just been emailed to you. Please check your email."
    else
      flash.now[:error] = "No user found with that email address."
    end
    render :action => :new
  end

  def edit
  end

  def update
    if @gamer.safe_update_attributes(params[:gamer], [ :password, :password_confirmation ])
      flash[:notice] = "Password successfully updated."
      redirect_to games_root_path
    else
      render :action => :edit
    end
  end

private

  def require_no_gamer
    unless current_gamer.nil?
      flash[:error] = "You must be logged out to reset passwords."
      redirect_to games_root_path
    end
  end

  def find_gamer_using_perishable_token
    @gamer = Gamer.find_using_perishable_token(params[:id])
    if @gamer.nil?
      flash[:error] = "Your password reset token has expired. Please request a new one."
      redirect_to new_games_password_reset_path
    end
  end

end
