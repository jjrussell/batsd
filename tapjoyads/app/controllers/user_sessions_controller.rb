class UserSessionsController < WebsiteController
  
  def new
    @user_session = UserSession.new
    @goto = params[:goto]
  end
  
  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      flash[:notice] = "Successfully logged in."
      redirect_to(params[:goto] || default_path)
    else
      @goto = params[:goto]
      render :action => 'new'
    end
  end
  
  def destroy
    user_session = UserSession.find
    unless user_session.nil?
      user_session.destroy
      flash[:notice] = "Successfully logged out."
    end
    redirect_to login_path
  end

  private

  def default_path
    options = {:user => @user_session.record}
    if permitted_to?(:index, :statz, options)
      statz_index_path
    elsif permitted_to?(:index, :tools, options)
      tools_path
    elsif permitted_to?(:index, :apps, options)
      apps_path
    else
      home_index_path
    end
  end
end
