class UserSessionsController < WebsiteController
  
  def new
    @user_session = UserSession.new
    @goto = params[:goto] || tools_path
  end
  
  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      flash[:notice] = "Successfully logged in."
      redirect_to params[:goto]
    else
      render :action => 'new'
    end
  end
  
  def destroy
    @user_session = UserSession.find
    unless @user_session.nil?
      @user_session.destroy
      flash[:notice] = "Successfully logged out."
    end
    redirect_to login_path
  end
  
end
